-- MODULE:  VGA_DRIVER
-- EN 202 Projet VHDL
-- Binome:
-- MAKARA, Felipe
-- BOURGOIN, Hugo
-- 
-- But du module: à partir des informations de pixels stockées dans une 
--    memoire RAM, ce module se connecte avec un ecran VGA et gêre les
--    synchronisations necessaires pour faire le ecran fonctioner.
--    Tous les timings ont êtês prises du User Guide de la plaque.
--    http://www.xilinx.com/support/documentation/boards_and_kits/ug230.pdf
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_DRIVER is Port ( 
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
end VGA_DRIVER;
architecture Behavioral of VGA_DRIVER is
SIGNAL INT_X, INT_Y : Integer;
SIGNAL X_ENABLE, Y_ENABLE: STD_LOGIC;
begin
	
	R_OUT <= RAM_IN(2) and X_ENABLE and Y_ENABLE;
	G_OUT <= RAM_IN(1) and X_ENABLE and Y_ENABLE;
	B_OUT <= RAM_IN(0) and X_ENABLE and Y_ENABLE;
	
	process (H)
	begin 
		if (H'event and H='1')then 
			if(RESET='1')then
				INT_X <= 0;
				INT_Y <= 0;
			else
				if INT_X<800 then 
					INT_X<=INT_X+1;
				else 
					INT_X<=0;
					if INT_Y<521 then 
						INT_Y<=INT_Y+1;
					else 
						INT_Y<=0;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process (INT_X)
	begin 
		if (INT_X<96) then 
			X_ADDR <= "0000000000";
			H_SYNC<='0';
			X_ENABLE<= '0';
		elsif (INT_X<(96+48)) then 
			X_ADDR <= "0000000000";
			H_SYNC<='1';
			X_ENABLE<= '0';
		elsif (INT_X<(96+48+640)) then 
			X_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(INT_X-96-48,10));
			H_SYNC<='1';
			X_ENABLE<= '1';
		else 
			X_ADDR <= "0000000000";
			H_SYNC<='1';
			X_ENABLE<= '0';
		end if;
	end process;
	
	process (INT_Y)
	begin 
		if (INT_Y<2) then 
			Y_ADDR <= "000000000";
			V_SYNC <= '0';
			Y_ENABLE <= '0';
			BLANK <= '0';
		elsif (INT_Y<(2+29)) then 
			Y_ADDR <= "000000000";
			V_SYNC <= '1';
			Y_ENABLE <= '0';
			BLANK <= '0';
		elsif (INT_Y<(2+29+480)) then 
			Y_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(INT_Y-2-29,9));
			V_SYNC <= '1';
			Y_ENABLE <= '1';
			BLANK <= '0';
		else 
			Y_ADDR <= "000000000";
			V_SYNC <= '1';
			Y_ENABLE <= '0';
			BLANK <= '1';
		end if;
	end process;
	
end Behavioral;
