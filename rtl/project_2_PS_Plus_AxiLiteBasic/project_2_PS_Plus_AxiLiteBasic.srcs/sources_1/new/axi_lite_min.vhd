----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Roger Vela
-- 
-- Create Date: 18.01.2026 17:55:41
-- Design Name: 
-- Module Name: axi_lite_min - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axi_lite_min is
  Port (
    -- AXI clock and reset
    ACLK     : in  std_logic;
    ARESETN  : in  std_logic;

    -- Write address channel
    AWADDR   : in  std_logic_vector(31 downto 0);
    AWVALID  : in  std_logic;
    AWREADY  : out std_logic;

    -- Write data channel
    WDATA    : in  std_logic_vector(31 downto 0);
    WSTRB    : in  std_logic_vector(3 downto 0);
    WVALID   : in  std_logic;
    WREADY   : out std_logic;

    -- Write response channel
    BRESP    : out std_logic_vector(1 downto 0);
    BVALID   : out std_logic;
    BREADY   : in  std_logic;

    -- Read address channel
    ARADDR   : in  std_logic_vector(31 downto 0);
    ARVALID  : in  std_logic;
    ARREADY  : out std_logic;

    -- Read data channel
    RDATA    : out std_logic_vector(31 downto 0);
    RRESP    : out std_logic_vector(1 downto 0);
    RVALID   : out std_logic;
    RREADY   : in  std_logic
  );
end axi_lite_min;

architecture rtl of axi_lite_min is
    -- Write channel latches
    signal awaddr_latched : std_logic_vector(31 downto 0); --AWADDR
    signal awaddr_valid   :  std_logic; --AWVALID
    signal s_awready : std_logic;
    --signal s_AWREADY  : std_logic;
    signal wdata_latched  : std_logic_vector(31 downto 0); --WDATA
    signal wdata_valid    : std_logic; --WVALID
    signal s_bvalid : std_logic;
    signal s_wready : std_logic;
    -- Read channel latches
    signal araddr_latched : std_logic_vector(31 downto 0); --ARADDR
    signal araddr_valid   :  std_logic; --ARVALID
    signal s_arready : std_logic;
    --signal s_ARREADY  : std_logic;
    signal rdata_latched  : std_logic_vector(31 downto 0); --WDATA
    signal rdata_valid    : std_logic; --WVALID
    --signal s_bvalid : std_logic;
    signal s_rready : std_logic;
    signal s_rvalid : std_logic;
begin
    -- Write channel signals
    s_awready <= not awaddr_valid;
    s_wready  <= not wdata_valid;
    BVALID  <= s_bvalid;
    -- Read channel signals
    s_arready <= not araddr_valid;
    s_rready <= not rdata_valid;
    s_rvalid <= not rdata_valid;

    
    
    process (ACLK)
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                --Write Channel
                awaddr_valid <= '0';
                wdata_valid <= '0';
                s_bvalid <= '0';
                BRESP <= "00";
                -- Read channel
                araddr_valid <= '0';
                rdata_valid <= '0';
            else
                -- Addres Write Channel --
                --Ready when no address is latched
                if(AWVALID = '1' and s_awready = '1') then
                    awaddr_latched <= AWADDR;
                    awaddr_valid <= '1';
                    --s_awready <= '0';
                end if;
                
                -- Write Channel --
                -- Ready when no data is latched
                if(WVALID = '1' and s_wready = '1') then
                    wdata_latched <= WDATA;
                    wdata_valid <= '1';
                end if;
                
                if (wdata_valid = '1' and awaddr_valid = '1' and s_bvalid = '0') then
                    s_bvalid <= '1';
                    BRESP <= "00"; -- OKAY
                end if;
                if(s_bvalid = '1' and BREADY = '1') then
                    s_bvalid <= '0';
                    awaddr_valid <= '0';
                    wdata_valid <= '0';
                end if;
                
                -- Address Read Channel --
                if(ARVALID = '1' and s_arready = '1') then
                    araddr_latched <= ARADDR;
                    araddr_valid <= '1';
                end if;
                -- Read Channel --
                if(s_rvalid = '1' and RREADY = '1') then
                    RDATA <= rdata_latched;
                    rdata_valid <= '1';
                end if;
                if(rdata_valid = '1' and RREADY = '1') then
                    araddr_valid <= '0';
                    rdata_valid <= '0';
                end if;
            end if;
        end if;
    end process;
    AWREADY <= s_awready;
    WREADY <= s_wready;
    RVALID <= rdata_valid;

end rtl;
