library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity irq_ctrl is
	port (
		cs : in std_logic;
		rw : in std_logic;
		addr : in std_logic_vector(3 downto 0);
		data : inout std_logic_vector(7 downto 0)
	);
end;

architecture arch of irq_ctrl is

signal vec : std_logic_vector(7 downto 0);

begin

vec <= "00011" & addr(3 downto 1);

data <= (others => 'Z') when cs = '0' or rw = '0' else vec;

end; 
