--   _______    __    ______     ______     _____    ________
--  |   ____|  |  |  |   _  \   |   _  \   / __  \  |___  ___|
--  |  |____   |  |  |  |_|  |  |  |_| /  | |  | |     |  |
--  |   ____|  |  |  |       |  |   _  \  | |  | |     |  |
--  |  |____   |  |  |  |\  \   |  |_| |  | |__| |     |  |
--  |_______|  |__|  |__| \__\  |______/   \_____/     |__|
--
-- Module: COUNTER_ROTATIF
-- But: Traduire les pulses que viennent d'un encoder pour des pulses qui 
-- vont entrer dans un compteur.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity COUNTER_ROTATIF is Port ( 
	H    : in  STD_LOGIC;
	SIG  : in  STD_LOGIC_VECTOR (1 downto 0);
	SORT : out STD_LOGIC_VECTOR (1 downto 0);
	RESET: in  STD_LOGIC
);
end COUNTER_ROTATIF; 

architecture Behavioral of COUNTER_ROTATIF is
SIGNAL BUFFIN: STD_LOGIC_VECTOR (1 downto 0);
SIGNAL BUFFOUT: STD_LOGIC_VECTOR(1 downto 0);
SIGNAL DIR: STD_LOGIC;
signal lastSig, lastBuffin: STD_LOGIC_VECTOR(1 downto 0);
begin
	SORT <= BUFFOUT;
	filtreRebound: process(H)
	begin
		if(H'event and H='1')then
			if(RESET='1')then
				BUFFIN <= "00";
			else
				if(SIG(0)/=lastSig(0))then
					BUFFIN(1) <= SIG(1);
				end if;
				if(SIG(1)/=lastSig(1))then
					BUFFIN(0) <= SIG(0);
				end if;
			end if;
			lastSig <= SIG;
		end if;
	end process;
	counter: process(H)
	begin
		if(H'event and H='1')then
			if(RESET='1')then
				BUFFOUT <= "00";
			else
				if(lastBuffin /= BUFFIN)then
					if(BUFFIN = "00" and BUFFOUT="00")then 
						BUFFOUT(0) <= DIR;
						BUFFOUT(1) <= not DIR;
					end if;
					if(BUFFIN = "11")then 
						BUFFOUT <= "00"; 
					end if;
					DIR <= BUFFIN(0);
				end if;
			end if;
			lastBuffin <= BUFFIN;
		end if;
	end process;
end Behavioral;
