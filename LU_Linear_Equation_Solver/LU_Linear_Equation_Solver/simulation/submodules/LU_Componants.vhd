library ieee;
use ieee.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity LU_Controller is
   port (
      clk, reset    : in  std_logic;
      address       : in  std_logic_vector (1 downto 0); 
      read          : in  std_logic;
      readdata      : out std_logic_vector (31 downto 0);
      write         : in  std_logic;
      writedata     : in  std_logic_vector (31 downto 0)
   );
end LU_Controller;

architecture simple of LU_Controller is

    constant MAX_WIDTH             : integer := 8;
    constant DIV_DELAY             : integer := 33;
    constant MULT_DELAY            : integer := 11;
    constant ADD_DELAY             : integer := 14;

    type MatrixA is array ((MAX_WIDTH * MAX_WIDTH)-1 downto 0) of std_logic_vector(31 downto 0);
    type MatrixB is array (MAX_WIDTH -1 downto 0) of std_logic_vector(31 downto 0);

   signal control_and_status_reg  : std_logic_vector (31 downto 0);
   signal Matrix_A                : MatrixA;
   signal Matrix_B                : MatrixB;
   signal result_value            : std_logic_vector (31 downto 0);
   signal k                       : integer := 0;
   signal i                       : integer := 0;
   signal j                       : integer := 0;
   signal l                       : integer := 0;
   signal Div_A                   :std_logic_vector(31 downto 0);
   signal Div_B                   :std_logic_vector(31 downto 0);
   signal Div_Result              :std_logic_vector(31 downto 0);  
   signal Mult_A                  :std_logic_vector(31 downto 0);
   signal Mult_B                  :std_logic_vector(31 downto 0);
   signal Mult_Result             :std_logic_vector(31 downto 0);
   signal Add_A                   :std_logic_vector(31 downto 0);
   signal Add_B                   :std_logic_vector(31 downto 0);
   signal Add_Result              :std_logic_vector(31 downto 0);
   signal add_sub		              :std_logic;
   signal k_increment             :std_logic;
   signal j_increment             :std_logic;
   signal LB_i_increment          :std_logic;
   signal UY_i_increment          :std_logic;
   signal division_by_zero        :std_logic;

   type tState is (stIDLE, stSTART, stPROCESSING, stFINISH);
   signal state : tState := stIDLE;
   signal i_state : tState := stIDLE;
   signal l_state : tState := stIDLE;
   signal LB_state : tState := stIDLE;
   signal LB_jstate : tState := stIDLE;
   signal UY_state : tState := stIDLE;
   signal UY_jstate : tState := stIDLE;
	
	component Float_32_Div IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    division_by_zero		: OUT STD_LOGIC ;
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	END component;
	
	component Float_32_Mult IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	END component;
	
	component Float_32_Add IS
	PORT
	(
    add_sub		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	END component;

begin

    FP_Div : Float_32_Div port map (clk, Div_A, Div_B,division_by_zero, Div_Result);
    FP_Adder : Float_32_Add port map (add_sub,clk, Add_A, Add_B, Add_Result);
    FP_Mult : Float_32_Mult port map (clk, Mult_A, Mult_B, Mult_Result);

    -- CPU is reading data at address.
    process (clk)
      variable out_data : std_logic_vector (31 downto 0);
      variable counterA : integer := 0;
      variable counterB : integer := 0;
      variable Count_i  : integer := 0;
      variable counter  : integer := 0;
      variable count    : integer := 0;
      variable Temp_Matrix : MatrixB;

    begin
      if (rising_edge (clk)) then
        if (read = '1') then
          case address is
            when "00" => 
              out_data := control_and_status_reg;
            when "01" => 
              if(counterA < (MAX_WIDTH * MAX_WIDTH)) then
                out_data := Matrix_A(counterA);
              end if;

            when "10" => 
              if(counterB < MAX_WIDTH) then
                out_data := Matrix_B(counterB);
              end if;

            when others => null;
          end case;

          readdata <= out_data;
          report "read : address [" & integer'image (to_integer (unsigned (address))) & "]";
          report "read : data [" & integer'image (to_integer (unsigned (out_data))) & "]";
        elsif (write = '1') then
          case address is
            when "00" => 
              if (writedata = x"00000001") then
                  state <= stSTART;
                  k_increment <= '1';
                  k <= 0;
              end if;
              control_and_status_reg <= writedata;

            when "01" => 
              if(counterA < (MAX_WIDTH * MAX_WIDTH)) then
                Matrix_A(counterA) <= writedata;
                control_and_status_reg <= std_logic_vector(to_unsigned(counterA, control_and_status_reg'length));
                counterA := counterA + 1;
              end if;

            when "10" => 
              if(counterB < MAX_WIDTH) then
                Matrix_B(counterB)<= writedata;
                control_and_status_reg <= std_logic_vector(to_unsigned(counterB, control_and_status_reg'length));
                counterB := counterB +1;
              end if;

            when "11" =>
              if (writedata = x"00000000") then
                counterA := 0;
                counterB := 0;

              elsif (writedata = x"00000001") then
                counterA := counterA + 1;
                counterB := counterB + 1;
              end if;
                
            when others => 
              null;

          end case;
          report "write : address [" & integer'image (to_integer (unsigned (address))) & "]";
          report "write : data [" & integer'image (to_integer (unsigned (writedata))) & "]";
        else
          case state is
            when stSTART =>
              control_and_status_reg <= x"00000003";
              state <= stPROCESSING;

            when stPROCESSING =>
              if(k_increment = '1') then
                if(k < (MAX_WIDTH - 1)) then
                  i <= k + 1;
                  j <= k + 1;
                  l <= k + 1;
                  i_state <= stSTART;
                else
                  LB_state <= stSTART;            -- If Outer Loop completes
                  k <= 0;
                end if;
                k_increment <= '0';
              end if;

              if(j_increment = '1') then
                if(j < MAX_WIDTH) then
                  l <= k + 1;
                  l_state <= stSTART;
                else
                  k <= k+1;         -- If Outer Loop completes
                  k_increment <= '1';

                end if;
                j_increment <= '0';
              end if;

            when stFINISH =>
              control_and_status_reg <= x"00000000";
              state <= stIDLE;
            when stIDLE =>
              state <= stIDLE;
          end case;
        end if;

        case i_state is
        when stSTART =>
            counter := 0;
            i_state <= stPROCESSING;

        when stPROCESSING =>
          counter := counter + 1;
          if(i < MAX_WIDTH) then
            Div_A <= Matrix_A(MAX_WIDTH * i + k);
            Div_B <= Matrix_A(MAX_WIDTH * k + k);
            i <= i + 1;
          end if;

          if(counter > (DIV_DELAY + 1)) then
            Matrix_A(MAX_WIDTH* ((counter - (DIV_DELAY + 1))  + k) + k) <= Div_Result; 
          end if;
          if((counter - (DIV_DELAY + 1)) >= (MAX_WIDTH - (k+1))) then
            i_state <= stFINISH;
          end if;
        when stFINISH =>
          j <= k + 1;
          j_increment <= '1';
          i_state <= stIDLE;
        when stIDLE =>
          NULL;

      end case;

      case l_state is
        when stSTART =>
          counter := 0;
          l_state <= stPROCESSING;
          add_sub <= '0';
        when stPROCESSING =>

          if(l < MAX_WIDTH) then
            l <= l + 1;
            Mult_A <= Matrix_A(MAX_WIDTH * l + k);
            Mult_B <= Matrix_A(MAX_WIDTH * k + j);
          end if;

          counter := counter + 1;
          if(counter > (MULT_DELAY+1) AND counter <= MULT_DELAY + MAX_WIDTH - k) then

            Add_A <= Matrix_A(MAX_WIDTH* (k+(counter-(MULT_DELAY+1))) + j);
            Add_B <= Mult_Result;          
          end if;

          if(counter > (MULT_DELAY + ADD_DELAY + 2)) then
            Matrix_A(MAX_WIDTH* (k+(counter- (MULT_DELAY + ADD_DELAY + 2))) + j) <= Add_Result;
          end if;
          
          if((counter - (MULT_DELAY + ADD_DELAY + 2)) >= (MAX_WIDTH - (k+1))) then
            l_state <= stFINISH;
          end if;

        when stFINISH =>
          j <= j + 1;
          j_increment <= '1';
          l_state <= stIDLE;
        when stIDLE =>
          NULL;

      end case;

      case LB_state is
        when stSTART =>
          i <= 1;
          LB_state <= stPROCESSING;
          LB_i_increment <= '1';
        when stPROCESSING =>

          if(LB_i_increment = '1') then

            if( i < MAX_WIDTH) then
              LB_jstate <= stSTART;
              j <= 0;
            else
              LB_state <= stFINISH;
            end if;
            LB_i_increment <= '0';
          end if;

        when stFINISH =>
          UY_state <= stSTART;
          LB_state <= stIDLE;
        when stIDLE =>
          NULL;

      end case;

        case LB_jstate is
        when stSTART =>

          LB_jstate <= stPROCESSING;
          counter := 0;
          count := 0;
          Temp_Matrix(0) := Matrix_B(0);

        when stPROCESSING =>

          counter := counter + 1;
          if(j < i) then
            Mult_A <= Matrix_A(MAX_WIDTH*i + j);
            Mult_B <= Matrix_B(j);
            j <= j+1;
          end if;

          if((Counter > (MULT_DELAY +1)) and counter <= (MULT_DELAY +1) + i) then
            Temp_Matrix(counter - (MULT_DELAY + 1)) := Mult_Result;
          end if;

          if(Counter = (MULT_DELAY + 3 + (count * (ADD_DELAY+1))) and (Counter - (MULT_DELAY + 2))  <= ((i-1) * Add_Delay)) then
            
            add_sub <= '1';
            if(count = 0) then
              Add_A <= Temp_Matrix(count + 1);
            else
              Add_A <= Add_Result;
            end if;
              Add_B <= Temp_Matrix(count + 2);
              count := count + 1;
          end if;

          if (Counter -  (MULT_DELAY + 3) = ( (i-1) * (ADD_Delay  + 1))) then
            add_sub <= '0';
            Add_A <= Matrix_B(i);
            if(count = 0) then
              Add_B <= Mult_Result;
            else 
              Add_B <= Add_Result;
            end if;
          end if;

          if(Counter -  (MULT_DELAY + 3) >= (i * (ADD_Delay  + 1))) then
            Matrix_B(i) <= Add_Result;
            LB_jstate <= stFINISH;
          end if;

        when stFINISH =>
          LB_i_increment <= '1';
          i <= i + 1;
          LB_jstate <= stIDLE;
        when stIDLE =>
          NULL;

      end case;

      case UY_state is
        when stSTART =>
          i <= MAX_WIDTH - 1;
          UY_state <= stPROCESSING;
          UY_i_increment <= '1';
        when stPROCESSING =>

          if(UY_i_increment = '1') then

            if( i >= 0) then
              UY_jstate <= stSTART;
              j <= i + 1;
            else
              UY_state <= stFINISH;
            end if;
            UY_i_increment <= '0';
          end if;

        when stFINISH =>
          UY_state <= stIDLE;
          state <= stFINISH;
        when stIDLE =>
          NULL;

      end case;

        case UY_jstate is
        when stSTART =>

          UY_jstate <= stPROCESSING;
          counter := 0;
          count := 0;

        when stPROCESSING =>

          counter := counter + 1;

          if(j < MAX_WIDTH) then
            Mult_A <= Matrix_A(MAX_WIDTH*i + j);
            Mult_B <= Matrix_B(j);
            j <= j+1;
          end if;

          if((Counter > (MULT_DELAY + 1)) and counter <= (MULT_DELAY + 1) + (MAX_WIDTH - i - 1) and i < MAX_WIDTH-1) then
            Temp_Matrix(counter - (MULT_DELAY + 1)) := Mult_Result;
          end if;

          if(Counter = (MULT_DELAY + 3 + (count * (ADD_DELAY+1))) and (Counter - (MULT_DELAY + 2))  <= ((MAX_WIDTH - i-2) * Add_Delay) and i < MAX_WIDTH-1) then
            
            add_sub <= '1';
            if(count = 0) then
              Add_A <= Temp_Matrix(count + 1);
            else
              Add_A <= Add_Result;
            end if;
              Add_B <= Temp_Matrix(count + 2);
              count := count + 1;
          end if;

          if (Counter -  (MULT_DELAY + 4) = ( (MAX_WIDTH - i-2) * (ADD_Delay  + 1)) and i < MAX_WIDTH-1) then
            add_sub <= '0';
            Add_A <= Matrix_B(i);
            if(count = 0) then
              Add_B <= Mult_Result;
            else 
              Add_B <= Add_Result;
            end if;
          end if;

          if(Counter -  (MULT_DELAY + 4) = ((MAX_WIDTH - i-1) * (ADD_Delay  + 1)) or i = MAX_WIDTH-1) then
          
            if( i = MAX_WIDTH -1) then
              Div_A <= Matrix_B(i);
            else
              Div_A <= Add_Result;
            end if;
              Div_B <= Matrix_A(MAX_WIDTH * i + i);
          end if;

          if(Counter -  (MULT_DELAY + DIV_Delay + 5) = ((MAX_WIDTH - i-1) * (ADD_Delay  + 1)) or (i = MAX_WIDTH-1 and counter > DIV_DELAY + 1)) then
            Matrix_B(i) <= Div_Result;
            UY_jstate <= stFINISH;
          end if;

        when stFINISH =>
          UY_i_increment <= '1';
          i <= i - 1;
          UY_jstate <= stIDLE;
        when stIDLE =>
          NULL;

      end case;

      end if;

    end process;

end simple;
