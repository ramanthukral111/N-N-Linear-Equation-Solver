library ieee;
use ieee.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity LU_Controller_tb is
end LU_Controller_tb;

architecture simple of LU_Controller_tb is

    signal      clk           : in  std_logic;
    signal      reset         : in  std_logic;
    signal      address       : in  std_logic_vector (1 downto 0); 
    signal      read          : in  std_logic;
    signal      readdata      : out std_logic_vector (31 downto 0);
    signal      write         : in  std_logic;
    signal      writedata     : in  std_logic_vector (31 downto 0);

    component LU_Controller is
    port (
      clk, reset    : in  std_logic;
      address       : in  std_logic_vector (1 downto 0); 
      read          : in  std_logic;
      readdata      : out std_logic_vector (31 downto 0);
      write         : in  std_logic;
      writedata     : in  std_logic_vector (31 downto 0)
    );
    end component;

    begin

    LU_Comtroller_Test : LU_Controller(clk, reset), address, read, readdata, write, writedata);

    process
    begin

    clk <= '0';

    for i in 0 to 63 loop
        read <= '1';
        clk <= '1';
        readdata <= 

    end process;

end simple;