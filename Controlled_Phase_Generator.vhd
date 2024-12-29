library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--------------------------------------------------------------------------------------------------
-- Entity: Controlled_Phase_Generator
-- Description: 
--   This module generates a continuously incrementing phase value controlled by a frequency control world.
--   The phase wraps around between -PI and +PI boundaries based on the input frequency control.
--   The output rate of phase change is determined by frequency_control_word and base increment.
--------------------------------------------------------------------------------------------------
entity Controlled_Phase_Generator is
generic (
   -- Base increment value for phase stepping. Higher values = faster base phase accumulation
   FREQUENCY_BASE_INCREMENT : integer := 256    
);
port (
   system_clock           : in  std_logic;                     -- Master clock input for synchronous operation
   frequency_control_word  : in  std_logic_vector(15 downto 0); -- Input word to control phase increment rate
   phase_accumulator_out  : out std_logic_vector(15 downto 0); -- Current phase value output
   output_valid_flag      : out std_logic                      -- Indicates valid phase output
);
end Controlled_Phase_Generator;

architecture behavioral of Controlled_Phase_Generator is
   -- Fixed-point representation of phase boundaries
   -- POSITIVE_PI_BOUNDARY represents +π in 16-bit fixed-point format (1.2.13)
   constant POSITIVE_PI_BOUNDARY : signed(15 downto 0) := "0110010010001000";    
   -- NEGATIVE_PI_BOUNDARY represents -π in 16-bit fixed-point format (1.2.13)
   constant NEGATIVE_PI_BOUNDARY : signed(15 downto 0) := "1001101101111000";    
   
   -- Internal signals for phase calculation and accumulation
   -- Phase accumulator stores the current phase value
   signal phase_accumulator_register : signed(15 downto 0) := (others => '0');  
   -- Holds the product of base increment and frequency tuning word
   signal frequency_increment_value  : signed(31 downto 0);    

begin
   -- Multiply base increment by frequency tuning word to get actual phase step size
   -- This determines how much the phase changes each clock cycle
   frequency_increment_value <= FREQUENCY_BASE_INCREMENT * signed(frequency_control_word);

   -- Main phase accumulation process
   -- Triggered on rising edge of system clock
   phase_accumulation_process: process(system_clock)
   begin
       if rising_edge(system_clock) then
           -- Set valid flag high as phase value is always valid after initialization
           output_valid_flag <= '1';  
           
           -- Check if next phase value would exceed +PI boundary
           if (phase_accumulator_register + frequency_increment_value(15 downto 0) < POSITIVE_PI_BOUNDARY) then
               -- If not exceeding boundary, increment phase by calculated step
               phase_accumulator_register <= phase_accumulator_register + frequency_increment_value(15 downto 0);
           else
               -- If exceeding boundary, wrap around to -PI
               phase_accumulator_register <= NEGATIVE_PI_BOUNDARY;
           end if;
       end if;
   end process phase_accumulation_process;

   -- Convert internal signed phase value to std_logic_vector for output
   phase_accumulator_out <= std_logic_vector(phase_accumulator_register);

end behavioral;

--------------------------------------------------------------------------------------------------
-- Usage Notes:
-- 1. frequency_control_word controls the rate of phase accumulation:
--    - Larger values cause faster phase changes
--    - Zero value stops phase accumulation
-- 2. Phase output is in fixed-point format ranging from -π to +π
-- 3. Output updates on every rising edge of system_clock
--------------------------------------------------------------------------------------------------