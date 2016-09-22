library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity GENERIC_GAME is Port ( 
	H          : in   STD_LOGIC;
	RESET      : in   STD_LOGIC;
	ADDR_RAM   : out  STD_LOGIC_VECTOR (8 downto 0);---\
	RAM_IN     : IN   STD_LOGIC_VECTOR (23 downto 0);--|
	RAM_OUT    : out  STD_LOGIC_VECTOR (23 downto 0);--|
	WE_RAM     : out  STD_LOGIC;-----------------------|--to Console
	ADDR_ROM   : in   STD_LOGIC_VECTOR(9 downto 0);----|
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
end GENERIC_GAME;

architecture Behavioral of GENERIC_GAME is
component ROM_DESSINS is Port ( 
	CLK      : in  STD_LOGIC;
	RESET    : in  STD_LOGIC;
	ADDR_OUT : in  STD_LOGIC_VECTOR (9 downto 0);
	DATA_OUT : out STD_LOGIC_VECTOR (17 downto 0);
	ADDR_IN  : in  STD_LOGIC_VECTOR (9 downto 0);
	DATA_IN  : in  STD_LOGIC_VECTOR (17 downto 0);
	WE       : in  STD_LOGIC
);
end component;
component kcpsm3 is Port (
	address       : out std_logic_vector(9 downto 0);
	instruction   : in std_logic_vector(17 downto 0);
	port_id       : out std_logic_vector(7 downto 0);
	write_strobe  : out std_logic;
	out_port      : out std_logic_vector(7 downto 0);
	read_strobe   : out std_logic;
	in_port       : in std_logic_vector(7 downto 0);
	interrupt     : in std_logic;
	interrupt_ack : out std_logic;
	reset         : in std_logic;
	clk           : in std_logic
);
end component;
component prog_rom_dp is port ( 
	clk         : in  std_logic ;
	reset       : in  std_logic ;
	address     : in  std_logic_vector( 9 downto 0 ) ;
	instruction : out std_logic_vector( 17 downto 0 );
	addr_in     : in  std_logic_vector( 9 downto 0 ) ;
	data_in     : in  std_logic_vector( 17 downto 0 );
	we          : in  STD_LOGIC
) ;
end component ;
component COUNTER_ROTATIF is Port ( 
	H    : in  STD_LOGIC;
	SIG  : in  STD_LOGIC_VECTOR (1 downto 0);
	SORT : out STD_LOGIC_VECTOR (1 downto 0);
	RESET: in  STD_LOGIC
);
end component; 
component SERIAL_ASSEMBLER is Port ( 
	H     : in  STD_LOGIC;
	RESET : in  STD_LOGIC;
	RX    : in  STD_LOGIC;
	VAR   : out STD_LOGIC_VECTOR(31 downto 0);
	READY : out STD_LOGIC
);
end component;
component SERIAL_RECEIVER is Port ( 
	H     : in  STD_LOGIC;
    RESET : in  STD_LOGIC;
	RX    : in  STD_LOGIC;
	VAR   : out STD_LOGIC_VECTOR(7 downto 0);
	READY : out STD_LOGIC;
	ERROR : out STD_LOGIC
);
end component;
-----------Signaux pour le processeur----------
Signal address: STD_LOGIC_VECTOR(9 downto 0);
Signal instruction: STD_LOGIC_VECTOR(17 downto 0);
Signal port_id, out_port, in_port: STD_LOGIC_VECTOR(7 downto 0);
Signal write_strobe, read_strobe, interrupt_ack: STD_LOGIC;
-------------Signaux pour le jeu---------------
Signal ram_addr_buff, leds_buff, rot_count, serial_data_in: STD_LOGIC_VECTOR(7 downto 0);
Signal ram_data_buff: STD_LOGIC_VECTOR(23 downto 0);
Signal strobe: STD_LOGIC;
Signal inc: STD_LOGIC_VECTOR(1 downto 0);
Signal bouton_rot: Integer;
Signal max_rot, min_rot : STD_LOGIC_VECTOR(7 downto 0);
-------------Signaux pour le serial-------------
Signal var_in_serial : STD_LOGIC_VECTOR(31 downto 0);
Signal werom, weram, wein, reset_proc, reset_processeur_sig : STD_LOGIC;
begin
	bouton: COUNTER_ROTATIF port map ( 
		H     => H,
		SIG   => ROT(1 downto 0),
		SORT  => inc,
		RESET => RESET
	);
	rom: ROM_DESSINS port map ( 
		CLK      => H,
		RESET    => RESET,
		ADDR_OUT => ADDR_ROM,
		DATA_OUT => DATA_ROM,
		ADDR_IN  => var_in_serial(29 downto 20),
		DATA_IN  => var_in_serial(17 downto 0),
		WE       => werom			
	);
	processeur: kcpsm3 PORT MAP (
		address       => address, 
		instruction   => instruction,
		port_id       => port_id,
		write_strobe  => write_strobe,
		out_port      => out_port,
		read_strobe   => read_strobe,
		in_port       => in_port,
		interrupt     => '0',
		interrupt_ack => interrupt_ack,
		reset         => reset_processeur_sig,
		clk           => H
	);
	reset_processeur_sig <= RESET or reset_proc;
	programme : prog_rom_dp port map ( 
		clk         => H,
		reset       => RESET,
		address     => address,
		instruction => instruction,
		addr_in     => var_in_serial(29 downto 20),
		data_in     => var_in_serial(17 downto 0),
		we          => weram
	) ;
	ADDR_RAM <= '0' & ram_addr_buff;
	LEDS <= leds_buff;
	RAM_OUT <= ram_data_buff;
	serial_data_in <= "00000000";
	
	rot_count <= STD_LOGIC_VECTOR(TO_UNSIGNED(bouton_rot,8));
	onPas: process(strobe, RESET)
	begin
		if(RESET = '1')then
			bouton_rot <= 0;
		elsif(strobe'event and strobe='1')then
			if( inc(0)='1')then
				if(max_rot=min_rot) or not (STD_LOGIC_VECTOR(TO_UNSIGNED(bouton_rot,8))=max_rot)then
					bouton_rot <= bouton_rot + 1;
				end if;
			else
				if(max_rot=min_rot) or not (STD_LOGIC_VECTOR(TO_UNSIGNED(bouton_rot,8))=min_rot)then
					bouton_rot <= bouton_rot - 1;
				end if;
			end if;
		end if;
	end process;
	
	onRead: process(H)
	begin
		if(H'event and H='1')then
			strobe <= inc(0) or inc(1);
			case(port_id)is
				when "00000000"=> --read-ram-addr
					in_port <= ram_addr_buff;
				when "00000001"=>--read-ram-addr
					in_port <= ram_addr_buff;
				when "00000010"=>--read-LEDS
					in_port <= leds_buff;
				when "00000011"=>--read (DATA(7 downto 0))
					in_port <= ram_data_buff(7 downto 0);
				when "00000100"=>--read (DATA(15 downto 8))
					in_port <= ram_data_buff(15 downto 8);
				when "00000101"=>--read (DATA(23 downto 16))
					in_port <= ram_data_buff(23 downto 16);
				when "00000110"=>--read boutons
					in_port <= ROT(2) & SWITCHES(2 downto 0) & NORTH & EAST & SOUTH & WEST;
				when "00000111"=>--read bouton_rotatif
					in_port <= rot_count;
				when "00001000"=>--read serial
					in_port <= serial_data_in;
				when "00001001"=>--read MIN_ROT
					in_port <= min_rot;
				when "00001010"=>--read MAX_ROT
					in_port <= max_rot ;
				when others => 
					in_port <= "00000000";
			end case;
		end if;
	end process;
	onWrite: process(H)
	begin
		if(H'event and H='1')then
			if(RESET='1')then
				ram_data_buff <= "000000000000000000000000";
				WE_RAM  <= '0';
				leds_buff <= "00000000";
				SERIAL_OUT <= '0';
				ram_addr_buff <= "00000000";
				min_rot <= "00000000";
				max_rot <= "11111111";
			else
				if(write_strobe='1')then
					case(port_id)is
						when "00000000"=> --read-ram-addr
							ram_addr_buff <= out_port;
							WE_RAM <= '0';
						when "00000001"=>--write_ram-addr
							ram_addr_buff <= out_port;
							WE_RAM <= '1';
						when "00000010"=>--write-LEDS
							leds_buff <= out_port;
							WE_RAM <= '0';
						when "00000011"=>--write (DATA(7 downto 0))
							ram_data_buff(7 downto 0) <= out_port;
							WE_RAM <= '0';
						when "00000100"=>--write (DATA(15 downto 8))
							ram_data_buff(15 downto 8) <= out_port;
							WE_RAM <= '0';
						when "00000101"=>--write (DATA(23 downto 16))
							ram_data_buff(23 downto 16) <= out_port;
							WE_RAM <= '0';
						when "00001001"=>--write MIN_ROT
							min_rot <= out_port;
							WE_RAM <= '0';
						when "00001010"=>--write MAX_ROT
							max_rot <= out_port;
							WE_RAM <= '0';
						when others => NULL;
					end case;
				else
					WE_RAM <= '0';
				end if;
			end if;
		end if;
	end process;
	-------------------------------SERIAL------------------------------
	werom <= (not var_in_serial(31)) and (not var_in_serial(30)) and wein;
	weram <= (var_in_serial(31) and (var_in_serial(30))) and wein;
	serial: SERIAL_ASSEMBLER port map ( 
		H     => H,
		RESET => RESET,
		RX    => SERIAL_IN,
		VAR   => var_in_serial,
		READY => wein
	);
	reset_processeur : process(H)
	begin
		if(H'event and H='1')then
			if(RESET='1')then
				reset_proc <= '0';
			elsif(wein='1')then
				if(var_in_serial(31 downto 20)="111111111111")then
					reset_proc <= '0';
				else
					reset_proc <= '1';
				end if;
			end if;
		end if;
	end process;
end Behavioral;