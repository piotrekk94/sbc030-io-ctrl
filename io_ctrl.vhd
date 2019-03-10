library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity io_ctrl is
	port (
		/* clock & reset */
		clk : in std_logic;
		rstn : in std_logic;
		/* video output */
		vcs : out std_logic;
		vub : out std_logic;
		vlb : out std_logic;
		mode : out std_logic_vector(1 downto 0);
		/* audio */
		arst : out std_logic;
		ssg_cs : out std_logic;
		ym_cs : out std_logic;
		ym_rw : out std_logic;
		ym_rd : out std_logic;
		clk4 : out std_logic;		
		/* ethernet */
		eth_sck : out std_logic;
		eth_so : out std_logic;
		eth_si : in std_logic;
		eth_cs : out std_logic;
		/* sd card */
		sd_miso : in std_logic;
		sd_mosi : out std_logic;
		sd_sck : out std_logic;
		sd_cs : out std_logic;
		/* buffers */
		doe : out std_logic;
		ddir : out std_logic;
		/* interrupt */
		mirq : out std_logic;
		/* data bus */
		data : inout std_logic_vector(7 downto 0);
		/* address bus */
		addr_lo : in std_logic_vector(3 downto 0);
		addr_mi : in std_logic_vector(19 downto 16);
		addr_hi : in std_logic_vector(31 downto 28);
		/* control bus */
		as : in std_logic;
		ds : in std_logic;
		rw : in std_logic;
		fc : in std_logic_vector(1 downto 0);
		dsack : out std_logic_vector(1 downto 0);
		siz : in std_logic_vector(1 downto 0);
		/* buffered controls */
		boe : out std_logic;
		brw : out std_logic;
		/* gpio */
		gpio : inout std_logic_vector(3 downto 0)
	);
end;

architecture arch of io_ctrl is

component gpio_ctrl is
	port (
		clk : in std_logic;
		rstn : in std_logic;
		
		cs : in std_logic;
		rw : in std_logic;
		addr : in std_logic_vector(3 downto 0);
		data : inout std_logic_vector(7 downto 0);

		gpio : inout std_logic_vector(3 downto 0)
	);
end component;

component addr_ctrl is
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
		spi_cs : out std_logic;
		irq_cs : out std_logic
	);
end component;

component irq_ctrl is
	port (
		cs : in std_logic;
		rw : in std_logic;
		addr : in std_logic_vector(3 downto 0);
		data : inout std_logic_vector(7 downto 0)
	);
end component;

component spi_ctrl is
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
end component;

signal gpio_cs, spi_cs, irq_cs : std_logic;
signal dsack_i : std_logic;
signal cs : std_logic;

begin

cs <= gpio_cs or spi_cs or irq_cs;

doe <= not cs;
ddir <= not rw;

/* video - unused */
vcs <= '1';
vub <= '1';
vlb <= '1';
mode <= "11";
/* audio - unused */
arst <= '1';
ssg_cs <= '1';
ym_cs <= '1';
ym_rw <= '1';
ym_rd <= '1';
clk4 <= '1';

mirq <= 'Z';

dsack(1) <= 'Z';
dsack(0) <= '0' when dsack_i = '0' and as = '0' else 'Z';

brw <= rw;
boe <= not rw;

gpioc : gpio_ctrl port map (
	clk => clk,
	rstn => rstn,
	cs => gpio_cs,
	rw => rw,
	addr => addr_lo,
	data => data,
	gpio => gpio
);

addrc : addr_ctrl port map (
	clk => clk,
	rstn => rstn,
	as => as,
	ds => ds,
	fc => fc,
	siz => siz,
	addr_lo => addr_lo,
	addr_mi => addr_mi,
	addr_hi => addr_hi,
	gpio_cs => gpio_cs,
	spi_cs => spi_cs,
	irq_cs => irq_cs
);

irqc : irq_ctrl port map (
	cs => irq_cs,
	rw => rw,
	addr => addr_lo,
	data => data
);

spic : spi_ctrl port map (
	clk => clk,
	rstn => rstn,
	cs => spi_cs,
	rw => rw,
	addr => addr_lo,
	data => data,
	mosi => sd_mosi,
	miso => sd_miso,
	sck => sd_sck,
	ss => sd_cs
);

dsackc : process(rstn, clk, cs)
variable cnt : integer range 0 to 3;
begin
	if(rstn = '0' or cs = '0')then
		cnt := 0;
		dsack_i <= '1';
	elsif(rising_edge(clk))then
		if(cnt = 2)then
			dsack_i <= '0';
		else
			cnt := cnt + 1;
		end if;
	end if;
end process;

end;
