-----------------------------------------------------------------
-- Module:  axis_gain_scaler.vhd
-- Purpose: AXI4-Stream gain scaler accelerator
--          Multiplies each 32-bit input sample by a fixed gain
--          Passes TLAST through for DMA framing
-- Author:  Roger Vela
-- Target:  Zynq-7000 / Zybo Z7-10
-----------------------------------------------------------------

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

entity axis_gain_scaler is
--  Port ( );
    generic (
        C_DATA_WIDTH : integer := 32;
        C_GAIN_WIDTH : integer := 8
    );
    port(
        aclk : in std_logic;
        areset: in std_logic;
        
        gain : in std_logic_vector(C_GAIN_WIDTH-1 downto 0);
        -- Slave AXI4-Stream (input from DMA MM2S)
        s_axis_tdata  : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast  : in  std_logic;

        -- Master AXI4-Stream (output to DMA S2MM)
        m_axis_tdata  : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast  : out std_logic
    );
end axis_gain_scaler;

architecture rtl of axis_gain_scaler is
    -- Internal pipeline registers
    signal data_reg   : std_logic_vector(C_DATA_WIDTH-1 downto 0);
    signal valid_reg  : std_logic;
    signal last_reg   : std_logic;

    -- Multiplication result (wider to avoid overflow)
    -- 32-bit data * 8-bit gain = 40-bit product, truncate to 32
    signal product : unsigned(C_DATA_WIDTH + C_GAIN_WIDTH - 1 downto 0);
    
    
begin
    s_axis_tready <= m_axis_tready;
    product <= unsigned(s_axis_tdata)*unsigned(gain);
    -- Using lower 32 bits here for clarity;
    data_reg <= std_logic_vector(product(C_DATA_WIDTH-1 downto 0));
    last_reg <= s_axis_tlast;
    valid_reg <= s_axis_tvalid;
    
    -- Drive outputs
    m_axis_tdata <= data_reg;
    m_axis_tlast <= last_reg;
    m_axis_tvalid <= valid_reg;
    
end rtl;
