-- FILE USED FOR BITS AND PIECES OF CODE
    
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

--S_DEFAULT -Done
--S_MISS
--S_WAIT_MEM
--S_WRITE_CACHE
--S_WRITE_BACK
--S_WB_WAIT
--S_SEND_CPU

    port (
        addrs_in     -- Address from CPU
        clk          -- Clock
        rst          -- Reset
        di_cpu_in    -- Read from CPU
        di_mem_in    -- Read mem
        control_in   -- Halt from CPU
        control_out  -- Halt to mem
        status_in    -- Recieve halt Status from mems
        status_out   -- Send halt Status to CPU
        di_cpu_out   -- Write to CPU
        di_mem_out   -- Write to mem
        addrs_out    -- Address to mem
    );
