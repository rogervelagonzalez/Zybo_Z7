-----------------------------------------------------------------
-- Module:  axis_gain_scaler.vhd (v2.0)
-- Purpose: AXI4-Stream gain scaler with AXI4-Lite control port
-- Register Map:
--   0x00 CTRL  [0]    = enable (1=active, 0=block)
--   0x04 GAIN  [7:0]  = gain multiplier
--   0x08 COUNT [31:0] = samples processed (read-only)
--   0x0C STATUS[1:0]  = {overflow, stream_active} (read-only)
--
-- AXI4-Lite: write-before-read ordering assumed (standard)
-- Stream:    combinational, 1 sample/clock throughput
--
-- Author:  Roger Vela
-- Target:  Zynq-7000 / Zybo Z7-10
-----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity axis_gain_scaler is
--  Port ( );
    generic (
        C_S_AXI_DATA_WIDTH : integer := 32;
        C_GAIN_WIDTH : integer := 8;
        C_AXIS_DATA_WIDTH : integer := 32;
        C_S_AXI_ADDR_WIDTH : integer := 4 -- 4 bits, 16 bytes, 4 registers
    );
    port (
        ---------------------------------------------------------------
        -- Clock and Reset (shared by AXI-Lite and AXI-Stream)
        ---------------------------------------------------------------
        s_axi_aclk    : in  std_logic;
        s_axi_aresetn : in  std_logic;
        
        ---------------------------------------------------------------
        -- AXI4-Lite Slave (Control Port)
        ---------------------------------------------------------------

        -- Write Address Channel
        s_axi_awaddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;

        -- Write Data Channel
        s_axi_wdata   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_wstrb   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;

        -- Write Response Channel
        s_axi_bresp   : out std_logic_vector(1 downto 0);
        s_axi_bvalid  : out std_logic;
        s_axi_bready  : in  std_logic;

        -- Read Address Channel
        s_axi_araddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;

        -- Read Data Channel
        s_axi_rdata   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_rresp   : out std_logic_vector(1 downto 0);
        s_axi_rvalid  : out std_logic;
        s_axi_rready  : in  std_logic;

        ---------------------------------------------------------------
        -- AXI4-Stream Slave (Data Input from DMA MM2S)
        ---------------------------------------------------------------

        s_axis_tdata  : in  std_logic_vector(C_AXIS_DATA_WIDTH-1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast  : in  std_logic;

        ---------------------------------------------------------------
        -- AXI4-Stream Master (Data Output to DMA S2MM)
        ---------------------------------------------------------------
        m_axis_tdata  : out std_logic_vector(C_AXIS_DATA_WIDTH-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast  : out std_logic
    );
end axis_gain_scaler;

architecture rtl of axis_gain_scaler is
    -- Register Map:
    --   0x00 CTRL  [0]    = enable (1=active, 0=block)
    --   0x04 GAIN  [7:0]  = gain multiplier
    --   0x08 COUNT [31:0] = samples processed (read-only)
    --   0x0C STATUS[1:0]  = {overflow, stream_active} (read-only)
    -- Register file
    signal reg_ctrl : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal reg_gain : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := x"00000001"; -- reset gain = 1 (pass-through)
    signal reg_count : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal reg_status : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    -- AXI4-Lite internal handshake signals
    signal axi_awready : std_logic := '0';
    signal axi_wready  : std_logic := '0';
    signal axi_bvalid  : std_logic := '0';
    signal axi_arready : std_logic := '0';
    signal axi_rvalid  : std_logic := '0';
    signal axi_tvalid : std_logic := '0';
    signal axi_rdata   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    -- Latch write address (AW and W channels may arrive in either order)
    signal aw_addr_reg : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

    -- Stream datapath signals
    signal enable_stream : std_logic;
    signal gain_value    : unsigned(C_GAIN_WIDTH-1 downto 0);
    signal product       : unsigned(C_AXIS_DATA_WIDTH + C_GAIN_WIDTH - 1 downto 0);
    signal sample_valid  : std_logic;  -- a sample is transferring

    -- Sample counter (stream clock domain = AXI-Lite clock here,
    -- same clock for both in this design)
    signal sample_count  : unsigned(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    
    
begin
    -- Drive register
    enable_stream <= reg_ctrl(0);
    gain_value <= unsigned(reg_gain(C_GAIN_WIDTH-1 downto 0));


    -------------------------------------------------------------------
    -- AXI4-Lite Write Address Channel (AW)
    --
    --   1. Detect when the master presents a valid address
    --      (s_axi_awvalid = '1') and you are not already busy
    --   2. Assert axi_awready for exactly ONE clock cycle
    --   3. Latch s_axi_awaddr into aw_addr_reg at that same moment
    --   4. On reset: awready = 0, aw_addr_reg = 0
    --
    -- Think of this as: "I see the address, I am grabbing it"
    -------------------------------------------------------------------
    p_aw : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                axi_awready  <= '0';
                aw_addr_reg  <= (others => '0');
            else
                if s_axi_awvalid = '1' and axi_awready = '0' then        -- condition to accept the address
                    axi_awready <= '1';
                    aw_addr_reg <= s_axi_awaddr;
                else
                    axi_awready <= '0';
                end if;
            end if;
        end if;
    end process p_aw;

    s_axi_awready <= axi_awready;

    -------------------------------------------------------------------
    -- AXI4-Lite Write Data Channel (W)
    --
    --   1. Detect when master presents valid data (s_axi_wvalid = '1')
    --      AND you have already accepted the address (axi_awready = '1')
    --      AND you are not already busy
    --   2. Assert axi_wready for exactly ONE clock cycle
    --   4. On reset: wready = 0
    --
    -- Think of this as: "I see the data AND I know the address, grabbing it"
    -- The actual register write happens in p_reg_write below.
    -------------------------------------------------------------------
    p_w : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                axi_wready <= '0';
            else
                if s_axi_wvalid = '1' and axi_wready = '0' and axi_awready = '1' then        -- condition to accept the data
                    axi_wready <= '1';
                else
                    axi_wready <= '0';
                end if;
            end if;
        end if;
    end process p_w;

    s_axi_wready <= axi_wready;

    -------------------------------------------------------------------
    -- Register Write Logic
    --
    --   Executes the actual register update.
    --   This fires when BOTH handshakes are complete:
    --     axi_wready = '1' AND s_axi_wvalid = '1'
    --   Use aw_addr_reg(3 downto 2) to select which register:
    --     "00" → reg_ctrl  (offset 0x00)
    --     "01" → reg_gain  (offset 0x04)
    --     "10" → reg_count (read-only, ignore writes)
    --     "11" → reg_status(read-only, ignore writes)
    --   For writable registers, loop over the 4 bytes and check
    --   wstrb(byte) before writing each byte slice.
    --   On reset: restore reg_ctrl and reg_gain to defaults.
    --
    -- Think of this as: the actual memory write operation
    -------------------------------------------------------------------
    p_reg_write : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                reg_ctrl <= (others => '0');
                reg_gain <= x"00000001"; -- pass through GAIN = 1
            else
                if s_axi_wvalid = '1' and axi_wready = '1'  then    -- condition: write handshake complete
                    case aw_addr_reg(3 downto 2) is
                        when "00" =>  -- CTRL register
                            for byte in 0 to (C_S_AXI_DATA_WIDTH/8 - 1) loop
                                if s_axi_wstrb(byte) = '1' then   -- check this byte's strobe
                                    reg_ctrl(byte*8+7 downto byte*8) <= s_axi_wdata(byte*8+7 downto byte*8);
                                end if;
                            end loop;

                        when "01" =>  -- GAIN register
                            for byte in 0 to (C_S_AXI_DATA_WIDTH/8 - 1) loop
                                if s_axi_wstrb(byte) = '1' then
                                    reg_gain(byte*8+7 downto byte*8) <= s_axi_wdata(byte*8+7 downto byte*8);
                                end if;
                            end loop;

                        when "10" =>  -- COUNT (read-only)
                            null;

                        when "11" =>  -- STATUS (read-only)
                            null;

                        when others =>
                            null;

                    end case;
                end if;
            end if;
        end if;
    end process p_reg_write;

    -------------------------------------------------------------------
    -- AXI4-Lite Write Response Channel (B)
    --
    --   1. Assert axi_bvalid AFTER the write data handshake completes
    --      (after axi_wready pulse)
    --   2. HOLD axi_bvalid HIGH until master acknowledges
    --      (s_axi_bready = '1')
    --   3. De-assert axi_bvalid the cycle AFTER bready is seen
    --   4. On reset: bvalid = 0
    --
    -- Think of this as: "I finished the write, here is your receipt.
    --                    I will hold it until you take it."
    --
    -- Common mistake: pulsing bvalid instead of holding it.
    -- The master may not be ready immediately — you MUST hold it.
    -------------------------------------------------------------------
    p_b : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                axi_bvalid <= '0';
            else
                if axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0' then       -- condition: write just completed, no response pending
                    axi_bvalid <= '1';
                elsif s_axi_bready = '1' and axi_bvalid = '1' then    -- condition: master acknowledged the response
                    axi_bvalid <= '0';
                end if;
            end if;
        end if;
    end process p_b;

    s_axi_bvalid <= axi_bvalid;
    s_axi_bresp  <= "00";   -- always OKAY

    -------------------------------------------------------------------
    -- AXI4-Lite Read Address Channel (AR)
    --
    --   1. Detect when master presents a valid read address
    --   2. Assert axi_arready for exactly ONE clock cycle
    --   3. On reset: arready = 0
    --
    -- Note: you do NOT need to latch araddr here because the read
    -- data process below can sample it directly in the same cycle
    -- that arready is asserted.
    -------------------------------------------------------------------
    p_ar : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                axi_arready <= '0';
            else
                if s_axi_arvalid = '1' and axi_arready = '0' then      -- condition to accept read address
                    axi_arready <= '1';
                else
                    axi_arready <= '0';
                end if;
            end if;
        end if;
    end process p_ar;

    s_axi_arready <= axi_arready;

    -------------------------------------------------------------------
    -- AXI4-Lite Read Data Channel (R)
    --
    --   1. One cycle after arready pulses, latch the correct register
    --      into axi_rdata and assert axi_rvalid
    --   2. Use s_axi_araddr(3 downto 2) to select the register:
    --        "00" → reg_ctrl
    --        "01" → reg_gain
    --        "10" → reg_count
    --        "11" → reg_status
    --   3. HOLD axi_rvalid until master acknowledges (s_axi_rready = '1')
    --   4. De-assert rvalid the cycle AFTER rready is seen
    --   5. On reset: rvalid = 0, rdata = 0
    -- "Here is your data, I will hold it until you take it."
    -------------------------------------------------------------------
    p_r : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                axi_rvalid <= '0';
                axi_rdata  <= (others => '0');
            else
                if axi_arready = '1' and s_axi_arvalid = '1' and axi_rvalid = '0' then     -- condition: read address accepted, no data pending
                    axi_rvalid <= '1';
                    case s_axi_araddr(3 downto 2) is
                        when "00"   => axi_rdata <= reg_ctrl;
                        when "01"   => axi_rdata <= reg_gain;
                        when "10"   => axi_rdata <= reg_count;
                        when "11"   => axi_rdata <= reg_status;
                        when others => axi_rdata <= (others => '0');
                    end case;
                elsif s_axi_rready = '1' then  -- condition: master acknowledged read data
                    axi_rvalid <= '0';
                end if;
            end if;
        end if;
    end process p_r;

    s_axi_rvalid <= axi_rvalid;
    s_axi_rdata  <= axi_rdata;
    s_axi_rresp  <= "00";

    -------------------------------------------------------------------
    -- Sample Counter
    --
    -- Your job here:
    --   Count every sample that successfully exits the M_AXIS port.
    --   A sample exits when ALL of these are true simultaneously:
    --     m_axis_tvalid = '1'   (you are presenting valid data)
    --     m_axis_tready = '1'   (downstream accepted it)
    --     enable_stream = '1'   (accelerator is active)
    --   Increment sample_count by 1 each time this occurs.
    --   On reset: sample_count = 0
    --   Wire sample_count into reg_count so the read channel can see it.
    -------------------------------------------------------------------
    sample_valid <= s_axis_tvalid and m_axis_tready and enable_stream;

    p_counter : process(s_axi_aclk)
    begin
        if rising_edge(s_axi_aclk) then
            if s_axi_aresetn = '0' then
                sample_count <= (others => '0');
            else
                if sample_valid = '1' then
                    sample_count <= sample_count + 1;
                end if;
            end if;
        end if;
    end process p_counter;

    reg_count  <= std_logic_vector(sample_count);
    reg_status <= (
        1 => s_axis_tvalid,   -- bit 1: upstream sending data
        0 => enable_stream,   -- bit 0: accelerator enabled
        others => '0'
    );

    -------------------------------------------------------------------
    -- AXI4-Stream Datapath
    --
    -- Your job here:
    --   1. Compute: product = s_axis_tdata * gain_value
    --   2. Drive m_axis_tdata from the lower 32 bits of product
    --   3. Gate m_axis_tvalid: only valid when enabled AND input valid
    --   4. Pass s_axis_tlast straight through to m_axis_tlast
    --   5. Drive s_axis_tready:
    --        When enabled:  follow m_axis_tready (backpressure passthrough)
    --        When disabled: always '1' (drain/discard incoming data)
    --      Why drain? If you block tready when disabled, the DMA MM2S
    --      channel stalls and may timeout. Draining lets DMA complete
    --      cleanly while your accelerator simply discards the samples.
    -------------------------------------------------------------------
    product <= unsigned(s_axis_tdata) * gain_value;

    m_axis_tdata  <= std_logic_vector(product(C_AXIS_DATA_WIDTH-1 downto 0));
    -- TVALID gated by enable and input valid
    m_axis_tvalid <= s_axis_tvalid and enable_stream;
    -- TLAST passes through unconditionally (DMA framing must be preserved)
    m_axis_tlast  <= s_axis_tlast;
    -- TREADY: accept input when downstream ready OR when disabled
    -- (drain mode: accept and discard when enable=0)
    s_axis_tready <= m_axis_tready when enable_stream = '1' else '1';

    
end rtl;
