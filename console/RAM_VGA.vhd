-- MODULE:  RAM_VGA
-- EN 202 Projet VHDL
-- Binome:
-- MAKARA, Felipe
-- BOURGOIN, Hugo
-- 
-- But du module: Implementer une memoire RAM dual-port avec 6 modules
--    BLOCK-RAM, en formant une memoire capable de contenir 120x80 pixels
-- 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_VGA is Port ( 
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
end RAM_VGA;

architecture Behavioral of RAM_VGA is
TYPE memoire IS ARRAY(0 to (128*128)-1) OF STD_LOGIC;--RAMBLOCKs  80x120
SIGNAL R0, G0, B0, R1, G1, B1 : memoire;
SIGNAL addrin, addrout: Integer;
SIGNAL addrinvect, addroutvect:STD_LOGIC_VECTOR(13 downto 0);
SIGNAL sor1, sor0 : STD_LOGIC_VECTOR(2 downto 0);
begin
	addrinvect <= ADDR_X_IN(6 downto 0)& ADDR_Y_IN(6 downto 0) ;
	addroutvect<= ADDR_X_OUT(8 downto 2)& ADDR_Y_OUT(8 downto 2);
	addrin <= TO_INTEGER(UNSIGNED(addrinvect));
	addrout <= TO_INTEGER(UNSIGNED(addroutvect));
	COLOR_OUT <= sor0 when (ADDR_X_OUT(9)='0') else sor1;
	Process(H)
	begin
		if(H'event and H='1')then
			if( (WE and not ADDR_X_IN(7))='1')then
				R0(addrin) <= COLOR_IN(2);
				G0(addrin) <= COLOR_IN(1);
				B0(addrin) <= COLOR_IN(0);
			end if;
		end if;
	end process;
	Process(H)
	begin
		if(H'event and H='1')then
			if((WE and ADDR_X_IN(7))='1')then
				R1(addrin) <= COLOR_IN(2);
				G1(addrin) <= COLOR_IN(1);
				B1(addrin) <= COLOR_IN(0);
			end if;
		end if;
	end process;
	Process(H)
	begin
		if(H'event and H='1')then
			sor0(2) <= R0(addrout);
			sor0(1) <= G0(addrout);
			sor0(0) <= B0(addrout);
		end if;
	end process;
	Process(H)
	begin
		if(H'event and H='1')then
			sor1(2) <= R1(addrout);
			sor1(1) <= G1(addrout);
			sor1(0) <= B1(addrout);
		end if;
	end process;
	
end Behavioral;

