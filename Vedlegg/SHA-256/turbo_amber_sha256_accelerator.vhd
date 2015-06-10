-- Interface to the SHA256 accelerator
-- Author: Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>

-- Based largely on the template code generated by Marton Teilgård's
-- tileGenerator.py script, but translated to VHDL to increase readability.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity turbo_amber_sha256_accelerator is
	port(
		i_clk : in std_logic;
		i_rst : in std_logic;

		-- Wishbone interface:
		i_wb_addr : in  std_logic_vector(31 downto 0);
		i_wb_sel  : in  std_logic_vector(15 downto 0);
		i_wb_we   : in  std_logic;
		o_wb_dat  : out std_logic_vector(127 downto 0);
		i_wb_dat  : in  std_logic_vector(127 downto 0);
		i_wb_cyc  : in  std_logic;
		i_wb_stb  : in  std_logic;
		o_wb_ack  : out std_logic;
		o_wb_err  : out std_logic;

		-- Interrupt output:
		o_irq        : out std_logic
	);
end entity turbo_amber_sha256_accelerator;

architecture behaviour of turbo_amber_sha256_accelerator is

	-- SHA256 accelerator component:
	component sha256 is
		port(
			clk    : in std_logic;
			reset  : in std_logic;
			enable : in std_logic;

			ready  : out std_logic; -- Ready to process the next block
			update : in  std_logic; -- Start processing the next block

			-- Input data:
			word_address : out std_logic_vector(3 downto 0); -- Word 0 .. 15
			word_input   : in std_logic_vector(31 downto 0);

			-- Intermediate and final hash values:
			hash_output : out std_logic_vector(255 downto 0);

			-- Debug port, used in simulation; leave unconnected:
			debug_port : out std_logic_vector(31 downto 0)
		);
	end component sha256;

	-- Pulse generator helper component:
	component pulse_generator is
		port(
			clk    : in std_logic;
			reset  : in std_logic;
			input  : in std_logic;
			output : out std_logic
		);
	end component pulse_generator;

	-- Accelerator signals:
	signal acc_reset : std_logic;
	signal acc_ready, acc_update : std_logic;

	-- Input buffer:
	type input_buffer_type is array(0 to 15) of std_logic_vector(31 downto 0);
	signal input_buffer :  input_buffer_type;
	signal input_buffer_index : std_logic_vector(3 downto 0);
	signal input_value : std_logic_vector(31 downto 0);

	-- Output buffer:
	signal output_buffer : std_logic_vector(255 downto 0);

	-- Control/status register signals:
	signal ctrl_update, ctrl_enable, ctrl_reset  : std_logic;

	-- Wishbone signals:
	signal wb_start_write, wb_start_write_d1 : std_logic;
	signal wb_start_read, wb_start_read_d1 : std_logic;
	signal wb_ack : std_logic;

	signal wb_wdata32 : std_logic_vector(31 downto 0);
	signal wb_rdata32 : std_logic_vector(31 downto 0);

begin

	o_irq <= acc_ready;
	acc_reset <= ctrl_reset or i_rst;

	accelerator: sha256
		port map(
			clk => i_clk,
			reset => acc_reset,
			enable => ctrl_enable,
			ready => acc_ready,
			update => acc_update,
			word_address => input_buffer_index,
			word_input => input_value,
			hash_output => output_buffer,
			debug_port => open
		);

	input_value <= input_buffer(to_integer(unsigned(input_buffer_index)));

	startpulse_generator: pulse_generator
		port map(
			clk => i_clk,
			reset => i_rst,
			input => ctrl_update,
			output => acc_update
		);

	------ Wishbone interface -------

	o_wb_ack <= wb_ack;
	o_wb_err <= '0';

	wb_start_write <= i_wb_stb and i_wb_we and (not wb_start_read_d1);
	wb_start_read <= i_wb_stb and (not i_wb_we) and (not wb_ack);
	wb_ack <= i_wb_stb and (wb_start_write or wb_start_read_d1);

	o_wb_dat <= wb_rdata32 & wb_rdata32 & wb_rdata32 & wb_rdata32;

	process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			wb_start_read_d1 <= '0';
		elsif rising_edge(i_clk) then
			wb_start_read_d1 <= wb_start_read;
		end if;
	end process;

	process(i_wb_addr)
	begin
		case i_wb_addr(3 downto 2) is
			when b"11" =>
				wb_wdata32 <= i_wb_dat(127 downto 96);
			when b"10" =>
				wb_wdata32 <= i_wb_dat(95 downto 64);
			when b"01" =>
				wb_wdata32 <= i_wb_dat(63 downto 32);
			when others =>
				wb_wdata32 <= i_wb_dat(31 downto 0);
		end case;
	end process;

	register_writes: process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			ctrl_enable <= '0';
			ctrl_update <= '0';
			ctrl_reset <= '0';
		elsif rising_edge(i_clk) then
			if wb_start_write = '1' then
				case i_wb_addr(11 downto 0) is
					-- Control register
					when x"000" =>
						ctrl_enable <= wb_wdata32(0);
						ctrl_update <= wb_wdata32(1);
						ctrl_reset  <= wb_wdata32(2);

					-- Reserved for use in testing and debugging:
					when x"004" =>
						-- Do nothing for now

					-- Input data registers:
					when x"008" =>
						input_buffer(0) <= wb_wdata32;
					when x"00c" =>
						input_buffer(1) <= wb_wdata32;
					when x"010" =>
						input_buffer(2) <= wb_wdata32;
					when x"014" =>
						input_buffer(3) <= wb_wdata32;
					when x"018" =>
						input_buffer(4) <= wb_wdata32;
					when x"01c" =>
						input_buffer(5) <= wb_wdata32;
					when x"020" =>
						input_buffer(6) <= wb_wdata32;
					when x"024" =>
						input_buffer(7) <= wb_wdata32;
					when x"028" =>
						input_buffer(8) <= wb_wdata32;
					when x"02c" =>
						input_buffer(9) <= wb_wdata32;
					when x"030" =>
						input_buffer(10) <= wb_wdata32;
					when x"034" =>
						input_buffer(11) <= wb_wdata32;
					when x"038" =>
						input_buffer(12) <= wb_wdata32;
					when x"03c" =>
						input_buffer(13) <= wb_wdata32;
					when x"040" =>
						input_buffer(14) <= wb_wdata32;
					when x"044" =>
						input_buffer(15) <= wb_wdata32;

					when others =>
						-- Do nothing
				end case;
			end if;
		end if;
	end process;

	register_reads: process(i_clk, i_rst)
	begin
		if i_rst = '1' then
			wb_rdata32 <= (others => '0');
		elsif rising_edge(i_clk) then
			if wb_start_read = '1' then
				case i_wb_addr(11 downto 0) is
					-- Status register:
					when x"000" =>
						wb_rdata32 <= (31 downto 4 => '0')
							& ctrl_enable & ctrl_reset & ctrl_update & acc_ready;

					-- Test and debug register:
					when x"004" =>
						wb_rdata32 <= x"feedbeef";

					-- Input data registers:
					when x"008" =>
						wb_rdata32 <= input_buffer(0);
					when x"00c" =>
						wb_rdata32 <= input_buffer(1);
					when x"010" =>
						wb_rdata32 <= input_buffer(2);
					when x"014" =>
						wb_rdata32 <= input_buffer(3);
					when x"018" =>
						wb_rdata32 <= input_buffer(4);
					when x"01c" =>
						wb_rdata32 <= input_buffer(5);
					when x"020" =>
						wb_rdata32 <= input_buffer(6);
					when x"024" =>
						wb_rdata32 <= input_buffer(7);
					when x"028" =>
						wb_rdata32 <= input_buffer(8);
					when x"02c" =>
						wb_rdata32 <= input_buffer(9);
					when x"030" =>
						wb_rdata32 <= input_buffer(10);
					when x"034" =>
						wb_rdata32 <= input_buffer(11);
					when x"038" =>
						wb_rdata32 <= input_buffer(12);
					when x"03c" =>
						wb_rdata32 <= input_buffer(13);
					when x"040" =>
						wb_rdata32 <= input_buffer(14);
					when x"044" =>
						wb_rdata32 <= input_buffer(15);

					-- Output data registers:
					when x"048" =>
						wb_rdata32 <= output_buffer(255 downto 224);
					when x"04c" =>
						wb_rdata32 <= output_buffer(223 downto 192);
					when x"050" =>
						wb_rdata32 <= output_buffer(191 downto 160);
					when x"054" =>
						wb_rdata32 <= output_buffer(159 downto 128);
					when x"058" =>
						wb_rdata32 <= output_buffer(127 downto 96);
					when x"05c" =>
						wb_rdata32 <= output_buffer(95 downto 64);
					when x"060" =>
						wb_rdata32 <= output_buffer(63 downto 32);
					when x"064" =>
						wb_rdata32 <= output_buffer(31 downto 0);

					-- Others are dead beef:
					when others =>
						wb_rdata32 <= x"deadbeef";
				end case;
			end if;
		end if;
	end process;

end architecture behaviour;

