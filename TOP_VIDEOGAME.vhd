library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity TOP_VIDEOGAME is Port ( 
	H       : in   STD_LOGIC;
	VIDEO_R : out  STD_LOGIC;
	VIDEO_G : out  STD_LOGIC;
	VIDEO_B : out  STD_LOGIC;
	VIDEO_H : out  STD_LOGIC;
	VIDEO_V : out  STD_LOGIC;
	ROT        : in   STD_LOGIC_VECTOR(2 downto 0);--\
	NORTH      : in   STD_LOGIC;---------------------|
	SOUTH      : in   STD_LOGIC;---------------------|
	EAST       : in   STD_LOGIC;---------------------|--To Board
	WEST       : in   STD_LOGIC;---------------------|
	LEDS       : out  STD_LOGIC_VECTOR(7 downto 0);--|
	SWITCHES   : in   STD_LOGIC_VECTOR(3 downto 0);--|
	SERIAL_OUT : out  STD_LOGIC;---------------------|
	SERIAL_IN  : in   STD_LOGIC ---------------------/
);
end TOP_VIDEOGAME;
architecture Behavioral of TOP_VIDEOGAME is
component GENERIC_GAME is Port ( 
	H          : in   STD_LOGIC;
	RESET      : in   STD_LOGIC;
	ADDR_RAM   : out  STD_LOGIC_VECTOR (8 downto 0);---\
	RAM_IN     : in  STD_LOGIC_VECTOR (23 downto 0);--|
	RAM_OUT    : out  STD_LOGIC_VECTOR (23 downto 0);--|
	WE_RAM     : out  STD_LOGIC;-----------------------|--to Console
	ADDR_ROM   : in   STD_LOGIC_VECTOR(9 downto 0);---|
	DATA_ROM   : out  STD_LOGIC_VECTOR(17 downto 0);---/
	ROT        : in   STD_LOGIC_VECTOR(2 downto 0);--\
	NORTH      : in   STD_LOGIC;---------------------|
	SOUTH      : in   STD_LOGIC;---------------------|
	EAST       : in   STD_LOGIC;---------------------|--To Board
	WEST       : in   STD_LOGIC;---------------------|
	LEDS       : out  STD_LOGIC_VECTOR(7 downto 0);--|
	SWITCHES   : in   STD_LOGIC_VECTOR(3 downto 0);--|
	SERIAL_OUT : out  STD_LOGIC;---------------------|
	SERIAL_IN  : in   STD_LOGIC ---------------------/
);
end component;
component CONSOLE is Port ( 
	H        : in   STD_LOGIC;
	RESET    : in   STD_LOGIC;
	VIDEO_R  : out  STD_LOGIC;
	VIDEO_G  : out  STD_LOGIC;
	VIDEO_B  : out  STD_LOGIC;
	VIDEO_H  : out  STD_LOGIC;
	VIDEO_V  : out  STD_LOGIC;
	ADDR_RAM : in   STD_LOGIC_VECTOR (8 downto 0);---\
	RAM_IN   : in   STD_LOGIC_VECTOR (23 downto 0);--|
	RAM_OUT  : out  STD_LOGIC_VECTOR (23 downto 0);--|
	WE_RAM   : in   STD_LOGIC;-----------------------|--to Console
	ADDR_ROM : out  STD_LOGIC_VECTOR(9  downto 0);---|
	DATA_ROM : in   STD_LOGIC_VECTOR(17 downto 0) ---/
);
end component;
Signal ADDR_RAM:STD_LOGIC_VECTOR (8 downto 0);
Signal RAM_IN  :STD_LOGIC_VECTOR (23 downto 0);
Signal RAM_OUT :STD_LOGIC_VECTOR (23 downto 0);
Signal WE_RAM:  STD_LOGIC;
Signal ADDR_ROM:STD_LOGIC_VECTOR(9  downto 0);
Signal DATA_ROM:STD_LOGIC_VECTOR(17 downto 0);
Signal REFRESH: STD_LOGIC;
Signal RESET: STD_LOGIC;
begin
	RESET <= SWITCHES(3);
	cons: CONSOLE port map ( 
		H        => H,
		RESET    => RESET,
		VIDEO_R  => VIDEO_R,
		VIDEO_G  => VIDEO_G,
		VIDEO_B  => VIDEO_B,
		VIDEO_H  => VIDEO_H,
		VIDEO_V  => VIDEO_V,
		ADDR_RAM => ADDR_RAM,
		RAM_IN   => RAM_IN,
		RAM_OUT  => RAM_OUT,
		WE_RAM   => WE_RAM,
		ADDR_ROM => ADDR_ROM,
		DATA_ROM => DATA_ROM
	);
	game: GENERIC_GAME Port MAP ( 
		H          => H,         
		RESET      => RESET,     
		ADDR_RAM   => ADDR_RAM,
		RAM_IN     => RAM_OUT,
		RAM_OUT    => RAM_IN,  
		WE_RAM     => WE_RAM,    
		ADDR_ROM   => ADDR_ROM,  
		DATA_ROM   => DATA_ROM,  
		ROT        => ROT,       
		NORTH      => NORTH,     
		SOUTH      => SOUTH,     
		EAST       => EAST,      
		WEST       => WEST,      
		LEDS       => LEDS,      
		SWITCHES   => SWITCHES,  
		SERIAL_OUT => SERIAL_OUT,
		SERIAL_IN  => SERIAL_IN 
	);
end Behavioral;


