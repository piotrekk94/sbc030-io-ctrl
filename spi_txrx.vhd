library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity spi_txrx is
	port (
		clk : in std_logic;
		rstn : in std_logic;
		
		start : in std_logic;
		done : out std_logic;
		
		data_i : in std_logic_vector(7 downto 0);
		data_o : out std_logic_vector(7 downto 0);
		
		mosi : out std_logic;
		miso : in std_logic;
		sck : out std_logic
	);
end;

architecture arch of spi_txrx is

signal reg : std_logic_vector(7 downto 0);

type state_type is (idle, busy);
signal state : state_type;
signal cnt : integer range 0 to 16;
signal miso_d : std_logic;

begin

data_o <= reg;

mosi <= reg(7);

process(clk, rstn)
begin
	if(rstn = '0')then
		state <= idle;
		cnt <= 0;
		sck <= '0';
		reg <= (others => '0');
	elsif(rising_edge(clk))then
		case state is
			when idle =>
				done <= '0';
				if(start = '1')then
					reg <= data_i;
					state <= busy;
					cnt <= 0;
				end if;
			when busy =>
				cnt <= cnt + 1;
				if(cnt mod 2 = 0)then
					sck <= '1';
					miso_d <= miso;
				else
					sck <= '0';
					reg <= reg(6 downto 0) & miso_d;
				end if;
				if(cnt = 16)then
					sck <= '0';
					done <= '1';
					state <= idle;
				end if;
			when others =>
				state <= idle;
		end case;
	end if;
end process;

end; 
