library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity gpio_ctrl is
	port (
		clk : in std_logic;
		rstn : in std_logic;
		
		cs : in std_logic;
		rw : in std_logic;
		addr : in std_logic_vector(3 downto 0);
		data : inout std_logic_vector(7 downto 0);

		gpio : inout std_logic_vector(1 downto 0);
		mode : out std_logic_vector(1 downto 0)
	);
end;

architecture arch of gpio_ctrl is

signal data_i : std_logic_vector(7 downto 0);

signal ddir, ddat, dlat, mode_i : std_logic_vector(1 downto 0);

begin

data_i <= "000000" & ddat when addr = "0000" else
			"000000" & dlat when addr = "0001" else
			"000000" & ddir when addr = "0010" else
			"000000" & mode_i when addr = "0011" else
			"00000000";

mode <= mode_i;
			
data <= (others => 'Z') when cs = '0' or rw = '0' else data_i;

dlat <= gpio when rising_edge(clk);

gen_gpio:
for i in 0 to 1 generate
	gpio(i) <= ddat(i) when ddir(i) = '1' else 'Z';
end generate gen_gpio;

process(clk, rstn)
begin
	if(rstn = '0')then
		ddir <= (others => '0');
		ddat <= (others => '0');
	elsif(rising_edge(clk))then
		if(cs = '1' and rw = '0')then
			if(addr = "0000")then
				ddat <= data(1 downto 0);
			elsif(addr = "0010")then
				ddir <= data(1 downto 0);
			elsif(addr = "0011")then
				mode_i <= data(1 downto 0);
			end if;
		end if;
	end if;
end process;

end; 
