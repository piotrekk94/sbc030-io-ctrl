library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity addr_ctrl is
	port (
		clk : in std_logic;
		rstn : in std_logic;
		
		as : in std_logic;
		ds : in std_logic;
		
		fc : in std_logic_vector(1 downto 0);
		siz : in std_logic_vector(1 downto 0);
		
		addr_lo : in std_logic_vector(3 downto 0);
		addr_mi : in std_logic_vector(19 downto 16);
		addr_hi : in std_logic_vector(31 downto 28);
		
		gpio_cs : out std_logic;
		spi0_cs : out std_logic;
		spi1_cs : out std_logic;
		iack_cs : out std_logic
	);
end;

architecture arch of addr_ctrl is

signal as_d, as_dd : std_logic;

begin

process(clk, rstn, as)
begin
	if(rstn = '0')then
		as_d <= '1';
		as_dd <= '1';
	elsif(rising_edge(clk))then
		as_d <= as;
		as_dd <= as_d;
	end if;
end process;

process(clk, rstn)
begin
	if(as = '1')then
		gpio_cs <= '0';
		spi0_cs <= '0';
		spi1_cs <= '0';
		iack_cs <= '0';
	elsif(rising_edge(clk))then
		gpio_cs <= '0';
		spi0_cs <= '0';
		spi1_cs <= '0';
		iack_cs <= '0';
		if(as_dd = '0')then
			if(fc = "11")then
				if(addr_mi = "1111")then
					iack_cs <= '1';
				end if;
			elsif(addr_hi = "1110")then
				if(addr_mi = "0000")then
					gpio_cs <= '1';
				elsif(addr_mi = "0001")then
					spi0_cs <= '1';
				elsif(addr_mi = "0010")then
					spi1_cs <= '1';
				end if;
			end if;
		end if;
	end if;
end process;

end; 
