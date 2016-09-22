-- MODULE:  CONSOLE
-- EN 202 Projet VHDL
-- Binome:
-- MAKARA, Felipe
-- BOURGOIN, Hugo
-- 
-- But du module: Le console reunirá les modules de VGA_DRIVER,
--    RAM_DESSINS, RAM_VGA et DESSINATEUR, en formant une espece de 
--    carte grafique. Cette carte se connecterá à un jeu.
-- 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity CONSOLE is Port ( 
	H        : in   STD_LOGIC;
	RESET    : in   STD_LOGIC;
	VIDEO_R  : out  STD_LOGIC;------\
	VIDEO_G  : out  STD_LOGIC;------|
	VIDEO_B  : out  STD_LOGIC;------|--au borne VGA
	VIDEO_H  : out  STD_LOGIC;------|
	VIDEO_V  : out  STD_LOGIC;------/
	ADDR_RAM : in   STD_LOGIC_VECTOR (8 downto 0);---\
	RAM_IN   : in   STD_LOGIC_VECTOR (23 downto 0);--|
	RAM_OUT  : out  STD_LOGIC_VECTOR (23 downto 0);--|
	WE_RAM   : in   STD_LOGIC;-----------------------|--au jeu
	ADDR_ROM : out  STD_LOGIC_VECTOR(9 downto 0);----|
	DATA_ROM : in   STD_LOGIC_VECTOR(17 downto 0) ---/
);
end CONSOLE;

architecture Behavioral of CONSOLE is
SIGNAL CLK_25: STD_LOGIC;
SIGNAL COLOR_VGA: STD_LOGIC_VECTOR(2 downto 0);
SIGNAL X_ADDR_VGA: STD_LOGIC_VECTOR(9 downto 0);
SIGNAL Y_ADDR_VGA: STD_LOGIC_VECTOR(8 downto 0);
SIGNAL COLOR_MEM: STD_LOGIC_VECTOR(2 downto 0);
SIGNAL X_ADDR_MEM: STD_LOGIC_VECTOR(7 downto 0);
SIGNAL Y_ADDR_MEM: STD_LOGIC_VECTOR(6 downto 0);
SIGNAL WE_VGA: STD_LOGIC;
Signal ram_dessins_addrout: STD_LOGIC_VECTOR(8 downto 0);
Signal ram_dessins_dataout: STD_LOGIC_VECTOR(23 downto 0);
Signal pret: STD_LOGIC;
Signal COMMANDE : STD_LOGIC;
component VGA_DRIVER is Port ( 
	H     : in  STD_LOGIC;-- !!!25MHZ
	RESET : in  STD_LOGIC;
	R_OUT : out STD_LOGIC;-- \
	G_OUT : out STD_LOGIC;-- |
	B_OUT : out STD_LOGIC;-- |--connectées au borne VGA
	H_SYNC: out STD_LOGIC;-- |
	V_SYNC: out STD_LOGIC;-- /
	RAM_IN: in  STD_LOGIC_VECTOR(2 downto 0);--RGB \
	X_ADDR: out STD_LOGIC_VECTOR(9 downto 0);--640 |--connectées à RAM DP
	Y_ADDR: out STD_LOGIC_VECTOR(8 downto 0);--480 /
	BLANK : out STD_LOGIC--'1' quand le ecran est à la zone "noire"
);
end component;
component RAM_VGA is Port ( 
	H          : in  STD_LOGIC;
	RESET      : in  STD_LOGIC;
	ADDR_X_OUT : in  STD_LOGIC_VECTOR (9 downto 0);--\
	ADDR_Y_OUT : in  STD_LOGIC_VECTOR (8 downto 0);--|--au VGA_DRIVER
	COLOR_OUT  : out STD_LOGIC_VECTOR (2 downto 0);--/
	ADDR_X_IN  : in  STD_LOGIC_VECTOR (7 downto 0);--\
	ADDR_Y_IN  : in  STD_LOGIC_VECTOR (6 downto 0);--|__au DESSINATEUR
	COLOR_IN   : in  STD_LOGIC_VECTOR (2 downto 0);--|
	WE         : in  STD_LOGIC                     --/
);
end component;
component DESSINATEUR is Port (
	H           : in  STD_LOGIC;
	RESET       : in  STD_LOGIC;
	RAM_DATA_IN : in  STD_LOGIC_VECTOR(23 downto 0);--\__POSICIONEMENTS DES DESSINS
	RAM_ADDR_IN : out STD_LOGIC_VECTOR(8 downto 0); --/
	ROM_DATA_IN : in  STD_LOGIC_VECTOR(17 downto 0);--\__DESSINS PRECHARGÈES
	ROM_ADDR_IN : out STD_LOGIC_VECTOR(9 downto 0); --/
	VIDEO_X_ADDR: out STD_LOGIC_VECTOR(7 downto 0);--\
	VIDEO_Y_ADDR: out STD_LOGIC_VECTOR(6 downto 0);-- |___BUFFER SORTIE
	VIDEO_COLOR : out STD_LOGIC_VECTOR(2 downto 0);-- |
	VIDEO_ENABLE: out STD_LOGIC;---------------------/
	COMMANDE    : in  STD_LOGIC;--'1' pour redessiner l'ecran, pas de besoin de mantenir ce level
	PRET        : out STD_LOGIC --'1' quand pret à recevoir de COMMANDE, '0' quand en train de dessiner
);
end component;
component RAM_DESSINS is Port ( 
	H          : in  STD_LOGIC;
	RESET      : in  STD_LOGIC;
	ADDR_OUT   : in  STD_LOGIC_VECTOR (8 downto 0);---\__au DESSINATEUR
	DATA_OUT   : out STD_LOGIC_VECTOR (23 downto 0);--/
	DATA_CHECK : out STD_LOGIC_VECTOR (23 downto 0);--\
	ADDR_IN    : in  STD_LOGIC_VECTOR (8 downto 0);---|__au JEU
	DATA_IN    : in  STD_LOGIC_VECTOR (23 downto 0);--|
	WE         : in  STD_LOGIC                      --/
);
end component;
begin
	dessin: DESSINATEUR PORT MAP (
		H            => H,
		RESET        => RESET,
		RAM_DATA_IN  => ram_dessins_dataout,
		RAM_ADDR_IN  => ram_dessins_addrout,
		ROM_DATA_IN  => DATA_ROM,
		ROM_ADDR_IN  => ADDR_ROM,
		VIDEO_X_ADDR => X_ADDR_MEM,
		VIDEO_Y_ADDR => Y_ADDR_MEM,
		VIDEO_COLOR  => COLOR_MEM,
		VIDEO_ENABLE => WE_VGA,
		COMMANDE     => COMMANDE,
		PRET         => pret
	);
	vga: VGA_DRIVER PORT MAP ( 
		H     => CLK_25,
		RESET => RESET,
		R_OUT => VIDEO_R,
		G_OUT => VIDEO_G,
		B_OUT => VIDEO_B,
		H_SYNC=> VIDEO_H,
		V_SYNC=> VIDEO_V,
		RAM_IN=> COLOR_VGA,
		X_ADDR=> X_ADDR_VGA,
		Y_ADDR=> Y_ADDR_VGA,
		BLANK => COMMANDE
	);
	ramvga: RAM_VGA PORT MAP (
		H          => H,
		RESET      => RESET,
		ADDR_X_OUT => X_ADDR_VGA,
		ADDR_Y_OUT => Y_ADDR_VGA,
		COLOR_OUT  => COLOR_VGA,
		ADDR_X_IN  => X_ADDR_MEM,
		ADDR_Y_IN  => Y_ADDR_MEM,
		COLOR_IN   => COLOR_MEM,
		WE         => WE_VGA  
	);
	ramdessins: RAM_DESSINS PORT MAP ( 
		H          => H,
		RESET      => RESET,
		ADDR_OUT   => ram_dessins_addrout,
		DATA_OUT   => ram_dessins_dataout,
		DATA_CHECK => RAM_OUT,
		ADDR_IN    => ADDR_RAM,
		DATA_IN    => RAM_IN,
		WE         => WE_RAM
	);
	process(H)
	begin
		if(H'event and H='1')then
			if(RESET='1')then
				CLK_25 <= '0';
			else
				CLK_25 <= not CLK_25;
			end if;
		end if;
	end process;
end Behavioral;


