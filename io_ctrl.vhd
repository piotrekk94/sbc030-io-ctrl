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
		eth_so : in std_logic;
		eth_si : out std_logic;
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
		gpio : in std_logic_vector(3 downto 0)
	);
end;

architecture arch of io_ctrl is

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
		spi0_cs : out std_logic;
		spi1_cs : out std_logic;
		iack_cs : out std_logic
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

signal gpio_cs, spi0_cs, spi1_cs, iack_cs : std_logic;
signal dsack_i : std_logic;
signal cs : std_logic;

signal clk4_i : std_logic := '0';

signal eth_irq_d, eth_irq_dd : std_logic;

signal eth_irq : std_logic;

begin

cs <= gpio_cs or spi0_cs or spi1_cs or iack_cs;

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

clk4 <= clk4_i;

mirq <= eth_irq;

dsack(1) <= 'Z';
dsack(0) <= '0' when dsack_i = '0' and as = '0' else 'Z';

brw <= rw;
boe <= not rw;

eth_irqc : process(rstn, clk)
begin
	if(rstn = '0')then
		eth_irq <= '1';
	elsif(rising_edge(clk))then
		if(eth_irq_dd = '1' and eth_irq_d = '0')then
			eth_irq <= '0';
		end if;
		if(fc = "11" and addr_lo(3 downto 1) = "011")then
			eth_irq <= '1';
		end if;
	end if;
end process;

eth_irq_ed : process(rstn, clk)
begin
	if(rstn = '0')then
		eth_irq_d <= '1';
		eth_irq_dd <= '1';
	elsif(rising_edge(clk))then
		eth_irq_d <= gpio(2);
		eth_irq_dd <= eth_irq_d;
	end if;
end process;

/*
gpioc : gpio_ctrl port map (
	clk => clk,
	rstn => rstn,
	cs => gpio_cs,
	rw => rw,
	addr => addr_lo,
	data => data,
	gpio => gpio
);
*/

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
	spi0_cs => spi0_cs,
	spi1_cs => spi1_cs,
	iack_cs => iack_cs
);

irqc : irq_ctrl port map (
	cs => iack_cs,
	rw => rw,
	addr => addr_lo,
	data => data
);

spi0 : spi_ctrl port map (
	clk => clk,
	rstn => rstn,
	cs => spi0_cs,
	rw => rw,
	addr => addr_lo,
	data => data,
	mosi => sd_mosi,
	miso => sd_miso,
	sck => sd_sck,
	ss => sd_cs
);

spi1 : spi_ctrl port map (
	clk => clk,
	rstn => rstn,
	cs => spi1_cs,
	rw => rw,
	addr => addr_lo,
	data => data,
	mosi => eth_si,
	miso => eth_so,
	sck => eth_sck,
	ss => eth_cs
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

clk4_gen : process(rstn, clk)
variable cnt : integer range 0 to 1;
begin
	if(rstn = '0')then
		cnt := 0;
		clk4_i <= '0';
	elsif(rising_edge(clk))then
		if(cnt = 1)then
			cnt := 0;
			clk4_i <= not clk4_i;
		else
			cnt := cnt + 1;
		end if;
	end if;
end process;

end;
