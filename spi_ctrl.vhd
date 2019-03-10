library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity spi_ctrl is
	port (
		clk : in std_logic;
		rstn : in std_logic;
		
		cs : in std_logic;
		rw : in std_logic;
		addr : in std_logic_vector(3 downto 0);
		data : inout std_logic_vector(7 downto 0);

		mosi : out std_logic;
		miso : in std_logic;
		sck : out std_logic;
		ss : out std_logic
	);
end;

architecture arch of spi_ctrl is

component spi_txrx is
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
end component;

signal data_in : std_logic_vector(7 downto 0);
signal data_out : std_logic_vector(7 downto 0);

signal data_i : std_logic_vector(7 downto 0);

signal ss_i : std_logic;

signal done : std_logic;
signal start : std_logic;

signal done_i : std_logic;

begin

data_in <= data;

ss <= ss_i;

data <= (others => 'Z') when cs = '0' or rw = '0' else data_i;

data_i <= "000000" & done_i & ss_i when addr = "0000" else
			data_out when addr = "0001" else
			"00000000";

process(clk, rstn)
begin
	if(rstn = '0')then
		done_i <= '1';
	elsif(rising_edge(clk))then
		if(done = '1')then
			done_i <= '1';
		end if;
		if(start = '1')then
			done_i <= '0';
		end if;
	end if;
end process;

process(clk, rstn)
begin
	if(rstn = '0')then
		ss_i <= '1';
		start <= '0';
	elsif(rising_edge(clk))then
		start <= '0';
		if(cs = '1' and rw = '0')then
			if(addr = "0000")then
				ss_i <= data_in(0);
			elsif(addr = "0001")then
				start <= '1';
			end if;
		end if;
	end if;
end process;

txrx : spi_txrx port map (
	clk => clk,
	rstn => rstn,
	
	start => start,
	done => done,
	
	data_i => data_in,
	data_o => data_out,
	
	mosi => mosi,
	miso => miso,
	sck => sck
);

end; 
