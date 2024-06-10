library ieee;
use ieee.std_logic_1164.all;

type bloc is array (3 downto 0) of std_logic_vector(4 downto 0);

type cache_line is record
        dirty   :  std_logic;
        tag     :  std_logic_vector(23 downto 0);
        valid   :  std_logic;
        blocks  :  bloc;
end record;

type cache_array is array (3 downto 0) of cache_line;

entity cache is
begin
    generic (
        S_DEFAULT       :   std_logic_vector(4 downto 0) := "00000";             -- Default: CPU generates address, Cache hits, sends data
        S_MISS          :   std_logic_vector(4 downto 0) := "00001";             -- Miss: CPU generates address, Cache misses, sends address and control to memory, sends halt to cpu
        S_WAIT_MEM      :   std_logic_vector(4 downto 0) := "00010";             -- Wait for Memory: Wait for memory to send data
        S_WRITE_CACHE   :   std_logic_vector(4 downto 0) := "00011";             -- Write Cache: Write data to cache, check if dirty
        S_WRITE_BACK    :   std_logic_vector(4 downto 0) := "00100";             -- Write Back: If dirty, write back to memory by sending blocks of data, one at a time
        S_WB_WAIT       :   std_logic_vector(4 downto 0) := "00101";             -- Write Back Wait: Wait for memory to stop sending halt, then send next block. When counter reaches 0, go to send cpu
        S_SEND_CPU      :   std_logic_vector(4 downto 0) := "00110";             -- Send CPU: Send data to CPU after writing, return to default
        S_ADDRS_GEN     :   std_logic_vector(4 downto 0) := "00111";             -- Address Generation: Generate address for memory
        S_
    );
    port (
        addrs_in    :   in std_logic_vector(31 downto 0);
        clk         :   in std_logic;
        rst         :   in std_logic;
        di_cpu_in   :   in std_logic_vector(31 downto 0);
        di_mem_in   :   in std_logic_vector(31 downto 0);
        control_in  :   in std_logic;
        status_in   :   in std_logic;
        status_out  :   out std_logic;
        di_cpu_out  :   out std_logic_vector(31 downto 0);
        di_mem_out  :   out std_logic_vector(31 downto 0);
        addrs_out   :   out std_logic_vector(31 downto 0);
        control_out :   out std_logic;
    );
end;

architecture cache_arq of cache is
begin
    signal cache_mem : cache_array;
    signal EA : std_logic_vector(3 downto 0)
    signal block_sel : integer := 0;
    signal line_sel : integer := 0;
    signal tag : std_logic_vector(23 downto 0);
    signal miss : std_logic := '0';
    signal dirty : std_logic := '0';
    signal dirty_data : std_logic_vector(31 downto 0);
    signal 

    -- Block select and Tag
    block_sel <= to_integer(unsigned(addrs_in(7 downto 4)));
    line_sel <= to_integer(unsigned(addrs_in()));
    tag <= addrs_in(31 downto 8);
    i : integer := 0;
    j : integer := 0;
    counter : integer := 8;

    FSM: process(clk, rst)
    begin
        if rising_edge(rst) then
            EA <= S_DEFAULT;
        elsif rising_edge(clk) then
            case EA is
                when S_DEFAULT =>
                    if miss = '1' then
                        EA <= S_MISS;
                    end if;
                when S_MISS =>
                    EA <= S_WAIT_MEM;
                when S_WAIT_MEM =>
                    if status_in = '1' then -- Memory has sent data
                        EA <= S_WRITE_CACHE;
                    end if;
                when S_WRITE_CACHE =>
                    if dirty = '1' then
                        EA <= S_WRITE_BACK;
                    else
                        EA <= S_SEND_CPU;
                    end if;
                when S_WRITE_BACK =>
                    if counter = 0 then
                        EA <= S_SEND_CPU;
                    else
                        EA <= S_WB_WAIT;
                    end if;
                when S_WB_WAIT =>
                    if status_in = '0' then
                        EA <= S_WRITE_BACK;
                    end if;
                when S_SEND_CPU =>
                    EA <= S_DEFAULT;
            end case;
        end if;
    end process FSM;

    S_LOGIC: process(clk, rst)
    begin
        if rising_edge(rst) then
            counter <= 8;
            miss <= '0';
            dirty <= '0';
            addrs_out <= (others => '0');
            dirty_data <= (others => '0');
            control_out <= '0';
            status_out <= '1';
            for i in 0 to 3 loop
                cache_mem(i).dirty <= '0';
                cache_mem(i).valid <= '0';
                cache_mem(i).tag <= (others => '0');
                for j in 0 to 3 loop
                    cache_mem(i).blocks(j) <= (others => '0');
                end loop;
            end loop;
        elsif rising_edge(clk) then
            case EA is:
                when S_DEFAULT =>
                    if cache_mem(line_sel).valid = '1' && cache_mem(line_sel).tag = tag then
                        di_cpu_out <= cache_mem(line_sel).blocks(block_sel);
                    else
                        miss <= '1';
                    end if;
                when S_MISS =>
                    addrs_out <= addrs_in;
                    control_out <= '1'; -- Halt CPU
                    status_out <= '0'; -- Send to memory
                when S_WAIT_MEM =>
                    -- Nothing to do
                when S_WRITE_CACHE =>
                    if cache_mem(line_sel).valid = '1' then
                        dirty <= '1';
                        dirty_data <= cache_mem(line_sel)
                    else
                        cache_mem(line_sel).valid <= '1';
                        cache_mem(line_sel).tag <= tag;
                        cache_mem(line_sel).blocks(block_sel) <= di_mem_in;
                    end if;