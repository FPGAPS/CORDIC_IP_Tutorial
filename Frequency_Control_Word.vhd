library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Frequency_Control_Word is
    generic (
        step_size : integer := 1;        -- Step size for increment or decrement
        delay_cycles : integer := 2000;-- Delay in clock cycles (20us for 100MHz clock)
        max_value: integer:=4;
        output_width : integer := 16    -- Bitwidth of the output
        
    );
    port (
        clk : in std_logic;             -- 100 MHz clock input
        FCW_output : out std_logic_vector(output_width - 1 downto 0)      -- Frequency control word output
    );
end entity;

architecture Behavioral of Frequency_Control_Word is
    signal counter : integer := 0;             -- Counter for delay
    signal FCW_value : unsigned(output_width - 1 downto 0) := (others => '0');
    signal direction_up : boolean := true;    -- Direction flag (true for increment, false for decrement)
    
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Increment counter for delay cycles
            if counter < delay_cycles - 1 then
                counter <= counter + 1;
            else
                counter <= 0; -- Reset counter

                -- Update FCW value based on direction
                if direction_up then
                    if FCW_value + to_unsigned(step_size, output_width) >= max_value then
                        FCW_value <= TO_UNSIGNED(max_value,output_width); -- Set to max value
                        direction_up <= false;  -- Change direction to decrement
                    else
                        FCW_value <= FCW_value + to_unsigned(step_size, output_width);
                    end if;
                else
                    if FCW_value <= to_unsigned(step_size, output_width) then
                        FCW_value <= to_unsigned(1, output_width); -- Set to minimum value
                        direction_up <= true;           -- Change direction to increment
                    else
                        FCW_value <= FCW_value - to_unsigned(step_size, output_width);
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Assign output
    FCW_output <= std_logic_vector(FCW_value); -- Convert to std_logic

end architecture;
