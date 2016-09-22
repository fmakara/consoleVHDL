-- MODULE:  DESSINATEUR
-- EN 202 Projet VHDL
-- Binome:
-- MAKARA, Felipe
-- BOURGOIN, Hugo
-- 
-- But du module: À partir d'une buffer de commandes de dessins, ecrire les dessins
--      qui sont gardées sur une memoire ROM dans une position determinée.
--		Quand le programme principal termine de ecrire sur le buffer, il 
--		envoi une commande, qui reste gardée jusqu'au prochain cycle de video
--		Quand la sortie de video est en train de reinitializer (le periode 
--		entre les frames), ce module va effectuer la operation qui consiste en:
--		-Lire un addresse de la RAM. Les 24 bits sont composées en octets de: 
--                 (nombre du dessin)(positionX)(positionY)
--		-Chercher le dessin dans la ROM. Les dessins sont composées par 18
--			bits qui representent:
--		---(taille<8>)(position<10>)  <-- celles-ci sont au debut de la ROM, à la position indiqué sur la RAM
--			    ou
--		---(color <3>)(posy <7>)(posx <8>)
--		-Aprés trouvé, copier la ROM dans la memoire du video
--		-Aprés tout le process, PRET <= '1'
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DESSINATEUR is Port (
	H            : in  STD_LOGIC;
	RESET        : in  STD_LOGIC;
	RAM_DATA_IN  : in  STD_LOGIC_VECTOR(23 downto 0);--\__POSICIONEMENTS DES DESSINS
	RAM_ADDR_IN  : out STD_LOGIC_VECTOR(8 downto 0); --/
	ROM_DATA_IN  : in  STD_LOGIC_VECTOR(17 downto 0);--\__DESSINS PRECHARGÈES
	ROM_ADDR_IN  : out STD_LOGIC_VECTOR(9 downto 0); --/
	VIDEO_X_ADDR : out STD_LOGIC_VECTOR(7 downto 0);--\
	VIDEO_Y_ADDR : out STD_LOGIC_VECTOR(6 downto 0);-- |___BUFFER SORTIE
	VIDEO_COLOR  : out STD_LOGIC_VECTOR(2 downto 0);-- |
	VIDEO_ENABLE : out STD_LOGIC;---------------------/
	COMMANDE     : in  STD_LOGIC;--'1' pour redessiner l'ecran, pas de besoin de mantenir ce level
	PRET         : out STD_LOGIC --'1' quand pret à recevoir de COMMANDE, '0' quand en train de dessiner
);
end DESSINATEUR;
architecture Behavioral of DESSINATEUR is
Signal etat, subetat : STD_LOGIC_VECTOR(1 downto 0);
Signal videox, videoy : Integer;
Signal ramaddr, romaddr, dessincounter, dessinpoint: Integer;
Signal positionx : STD_LOGIC_VECTOR(7 downto 0);
Signal positiony : STD_LOGIC_VECTOR(6 downto 0);
Signal positionxdeplace, positionydeplace: Integer; 
begin
	process(etat, videox, videoy, positiony, positionx, ROM_DATA_IN, positionxdeplace, positionydeplace, RAM_DATA_IN)
	begin
		case etat is
			when "01" =>
				VIDEO_X_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(videox,8));
				VIDEO_Y_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(videoy,7));
				VIDEO_COLOR <= RAM_DATA_IN(2 downto 0);
			when "10" =>
				VIDEO_X_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(positionxdeplace, 8));
				VIDEO_Y_ADDR <= STD_LOGIC_VECTOR(TO_UNSIGNED(positionydeplace, 7));
				VIDEO_COLOR  <= ROM_DATA_IN(17 downto 15);
			when others =>
				VIDEO_X_ADDR <= "00000000";
				VIDEO_Y_ADDR <= "0000000";
				VIDEO_COLOR <= "000";
		end case;
	end process;
	positionxdeplace <= TO_INTEGER(UNSIGNED(ROM_DATA_IN(7 downto 0)))  + TO_INTEGER(UNSIGNED(positionx));
	positionydeplace <= TO_INTEGER(UNSIGNED(ROM_DATA_IN(14 downto 8))) + TO_INTEGER(UNSIGNED(positiony));
	ROM_ADDR_IN <= STD_LOGIC_VECTOR(TO_UNSIGNED(romaddr,10));
	RAM_ADDR_IN <= STD_LOGIC_VECTOR(TO_UNSIGNED(ramaddr,9));
	
	PRET <= not(etat(0) or etat(1));
	Process(H)
	begin
		if(H'event and H='0')then
			if(RESET='1')then
				etat <= "00";
				VIDEO_ENABLE <= '0';
				videox <= 0;
				videoy <= 0;
				subetat <= "00";
				ramaddr <= 0;
				romaddr <= 0;
			else
				case etat is
					when "00" => --demarage
						if(COMMANDE = '1')then
							etat <= "01";
							videox <= 0;
							videoy <= 0;
							VIDEO_ENABLE <= '1';
						end if;
					when "01" => --vidage de la memoire
						if(videox=160)then
							videox <= 0;
							if(videoy=120)then
								videoy <= 0;
								etat <= "10";
								VIDEO_ENABLE <= '0';
								--iniciaization de la prochaine machine d'etats
								ramaddr <= 1;
								romaddr <= 0;
								dessincounter <= 0;
							else
								videoy <= videoy + 1;
							end if;
						else
							videox <= videox + 1;
						end if;
					when "10" => --ecriture des elements
						case subetat is
							when "00" => --initialization
								if(RAM_DATA_IN(23 downto 16)="11111111")then
									subetat <= "11";
								else
									romaddr <= TO_INTEGER(UNSIGNED(RAM_DATA_IN(23 downto 16)));
									positionx <= RAM_DATA_IN(7 downto 0);
									positiony <= RAM_DATA_IN(14 downto 8);
									subetat <= "01";
								end if;
							when "01" => --cherche du dessin
								romaddr <= TO_INTEGER(UNSIGNED(ROM_DATA_IN(9 downto 0)));
								dessincounter <= TO_INTEGER(UNSIGNED(ROM_DATA_IN(17 downto 10)));
								--VIDEO_ENABLE <= '1';
								subetat <= "10";
							when "10" => --transfert du dessin
								if(dessincounter = 0)then
									subetat <= "11";
									VIDEO_ENABLE <= '0';
								else
									dessincounter <= dessincounter - 1;
									VIDEO_ENABLE <= '1';
									romaddr <= romaddr + 1;
								end if;
							when others => --reinitialization/finalization
								subetat <= "00";
								if(ramaddr=511)then
									etat <= "00";
									ramaddr <= 0;
									romaddr <= 0;
								else
									ramaddr <= ramaddr + 1;
								end if;
						end case;
					when others => 
						etat <= "00";
				end case;	
			end if;
		end if;
	end process;
end Behavioral;
