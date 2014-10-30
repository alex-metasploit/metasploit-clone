#    This file is part of Metasm, the Ruby assembly manipulation suite
#    Copyright (C) 2006-2009 Yoann GUILLOT
#
#    Licence is LGPL, see LICENCE in the top-level directory


require 'metasm/gui/dasm_hex'
require 'metasm/gui/dasm_listing'
require 'metasm/gui/dasm_opcodes'
require 'metasm/gui/dasm_coverage'
require 'metasm/gui/dasm_graph'
require 'metasm/gui/dasm_decomp'

module Metasm
module Gui
# the main disassembler widget: this is a container for all the lower-level widgets that actually render the dasm state
class DisasmWidget < ContainerChoiceWidget
	attr_accessor :dasm, :entrypoints, :gui_update_counter_max
	attr_accessor :keyboard_callback, :keyboard_callback_ctrl	# hash key => lambda { |key| true if handled }
	attr_accessor :clones
	attr_accessor :pos_history, :pos_history_redo
	attr_accessor :bg_color_callback	# proc { |address|  "rgb" # "00f" -> blue }
	attr_accessor :focus_changed_callback
	attr_accessor :parent_widget

	def initialize_widget(dasm, ep=[])
		@dasm = dasm
		@dasm.gui = self
		@entrypoints = ep
		@pos_history = []
		@pos_history_redo = []
		@keyboard_callback = {}
		@keyboard_callback_ctrl = {}
		@clones = [self]
		@parent_widget = nil
		@gui_update_counter_max = 100
		@dasm.callback_prebacktrace ||= lambda { Gui.main_iter }
		start_disassemble_bg

		addview :listing,   AsmListingWidget.new(@dasm, self)
		addview :graph,     GraphViewWidget.new(@dasm, self)
		addview :decompile, CdecompListingWidget.new(@dasm, self)
		addview :opcodes,   AsmOpcodeWidget.new(@dasm, self)
		addview :hex,       HexWidget.new(@dasm, self)
		addview :coverage,  CoverageWidget.new(@dasm, self)

		view(:listing).grab_focus
	end

	# start an idle callback that will run one round of @dasm.disassemble_mainiter
	def start_disassemble_bg
		gui_update_counter = 0
		run = false
		Gui.idle_add {
			# metasm disassembler loop
			# update gui once in a while
			if run or not @entrypoints.empty? or not @dasm.addrs_todo.empty?
				protect { run = @dasm.disassemble_mainiter(@entrypoints) }
				gui_update_counter += 1
				if gui_update_counter > @gui_update_counter_max
					gui_update_counter = 0
					gui_update
				end
				true
			else
				gui_update
				false
			end
		}
	end

	def terminate
		@clones.delete self
	end

	# returns the address of the item under the cursor in current view
	def curaddr
		curview.current_address
	end

	# returns the object under the cursor in current view (@dasm.decoded[curaddr])
	def curobj
		@dasm.decoded[curaddr]
	end

	# returns the address of the label under the cursor or the address of the line of the cursor
	def pointed_addr
		hl = curview.hl_word
		if hl =~ /^[0-9].*h$/ and a = hl.to_i(16) and @dasm.get_section_at(a)
			return a
		end
		@dasm.prog_binding[hl] || curview.current_address
	end

	# parse an address and change it to a canonical address form
	# supported formats: label names, or string with numerical value, incl hex (0x42 and 42h)
	# if the string is full decimal, a check against mapped space is done to find if it is
	# hexadecimal (eg 08048000)
	def normalize(addr)
		case addr
		when ::String
			if @dasm.prog_binding[addr]
				addr = @dasm.prog_binding[addr]
			elsif (?0..?9).include? addr[0] or (?a..?f).include? addr.downcase[0]
				case addr
				when /^0x/i
				when /h$/i; addr = '0x' + addr[0...-1]
				when /[a-f]/i; addr = '0x' + addr
				when /^[0-9]+$/
					addr = '0x' + addr if not @dasm.get_section_at(addr.to_i) and
								  @dasm.get_section_at(addr.to_i(16))
				end
				begin
					addr = Integer(addr)
				rescue ::ArgumentError
					return
				end
			else
				return
			end
		end
		addr
	end

	# display the specified address
	# the display first searches in the current view (graph, listing, etc),
	# if it cannot display the address all other views are tried in order
	# the current focus address is saved in @pos_history (see focus_addr_back/redo)
	# a messagebox is popped if no view can display the address unless quiet is true
	def focus_addr(addr, viewidx=nil, quiet=false)
		viewidx ||= curview_index || :listing
		return if not addr
		return if viewidx == curview_index and addr == curaddr
		oldpos = [curview_index, (curview.get_cursor_pos if curview)]
		if [viewidx, oldpos[0], *view_indexes].compact.uniq.find { |i|
			o_p = view(i).get_cursor_pos
			if view(i).focus_addr(addr)
				view(i).gui_update if i != oldpos[0]
				showview(i)
				true
			else
				view(i).set_cursor_pos o_p
				false
			end
		}
			@pos_history << oldpos if oldpos[0]	# ignore start focus_addr
			@pos_history_redo.clear
			true
		else
			messagebox "Invalid address #{addr}" if not quiet
			if oldpos[0]
				showview oldpos[0]
				curview.set_cursor_pos oldpos[1]
			end
			false
		end
	end

	# focus on the last address seen before the last focus_addr
	def focus_addr_back(val = @pos_history.pop)
		return if not val
		@pos_history_redo << [curview_index, curview.get_cursor_pos]
		showview val[0]
		curview.set_cursor_pos val[1]
		true
	end

	# undo focus_addr_back
	def focus_addr_redo
		if val = @pos_history_redo.pop
			@pos_history << [curview_index, curview.get_cursor_pos]
			showview val[0]
			curview.set_cursor_pos val[1]
		end
	end

	# ask the current view to update itself and redraw (incl all cloned widgets)
	def gui_update
		@clones.each { |c| c.do_gui_update }
	end

	# ask the current view to update itself
	def do_gui_update
		curview.gui_update	# invalidate all views ?
	end

	# redraw the window
	def redraw
		curview.redraw
	end

	# calls focus_addr(pre_yield_curaddr) after yield
	def keep_focus_while
		addr = curaddr
		yield
		focus_addr curaddr if addr
	end
	
	# calls listwindow with the same argument, but also creates a new bg_color_callback
	# that will color lines whose address is to be found in list[0] in green
	# the callback is put only for the duration of the listwindow, and is not reentrant.
	def list_bghilight(title, list, a={}, &b)
		prev_colorcb = bg_color_callback
		hash = list[1..-1].inject({}) { |h, l| h.update Expression[l[0] || :unknown].reduce => true }
		@bg_color_callback = lambda { |addr| hash[addr] ? '0f0' : prev_colorcb ? prev_colorcb[addr] : nil }
		redraw
		popupend = lambda { @bg_color_callback = prev_colorcb ; redraw }
		listwindow(title, list, a.merge(:ondestroy => popupend), &b)
	end

	# add/change a comment @addr
	def add_comment(addr)
		cmt = @dasm.comment[addr].to_a.join(' ')
		if di = @dasm.di_at(addr)
			cmt += di.comment.to_a.join(' ')
		end
		inputbox("new comment for #{Expression[addr]}", :text => cmt) { |c|
			c = c.split("\n")
			c = nil if c == []
			if di = @dasm.di_at(addr)
				di.comment = c
			else
				@dasm.comment[addr] = c
			end
			gui_update
		}
	end

	# disassemble from this point
	# if points to a call, make it return
	def disassemble(addr)
		if di = @dasm.di_at(addr) and di.opcode.props[:saveip]
			di.block.each_to_normal { |t|
				t = @dasm.normalize t
				next if not @dasm.decoded[t]
				@dasm.function[t] ||= @dasm.function[:default] ? @dasm.function[:default].dup : DecodedFunction.new
			}
			di.block.add_to_subfuncret(di.next_addr)
			@dasm.addrs_todo << [di.next_addr, addr, true]
		elsif addr
			@dasm.addrs_todo << [addr]
		end
		start_disassemble_bg
	end

	# disassemble fast from this point (don't dasm subfunctions, don't backtrace)
	def disassemble_fast(addr)
		@dasm.disassemble_fast(addr)
		gui_update
	end

	# disassemble fast & deep from this point (don't backtrace, but still dasm subfuncs)
	def disassemble_fast_deep(addr)
		@dasm.disassemble_fast_deep(addr)
		gui_update
	end

	# (re)decompile
	def decompile(addr)
		if @dasm.c_parser and var = @dasm.c_parser.toplevel.symbol[addr] and (var.type.kind_of? C::Function or @dasm.di_at(addr))
			@dasm.decompiler.redecompile(addr)
			view(:decompile).curaddr = nil
		end
		focus_addr(addr, :decompile)
	end

	# change the format of displayed data under addr (byte, word, dword, qword)
	# currently this is done using a fake empty xref
	def toggle_data(addr)
		return if @dasm.decoded[addr] or not @dasm.get_section_at(addr)
		@dasm.add_xref(addr, Xref.new(nil, nil, 1)) if not @dasm.xrefs[addr]
		@dasm.each_xref(addr) { |x|
			x.len = {1 => 2, 2 => 4, 4 => 8}[x.len] || 1
			break
		}
		gui_update
	end

	def list_functions
		list = [['name', 'addr']]
		@dasm.function.keys.each { |f|
			addr = @dasm.normalize(f)
			next if not @dasm.di_at(addr)
			list << [@dasm.get_label_at(addr), Expression[addr]]
		}
		title = "list of functions"
		listwindow(title, list) { |i| focus_addr i[1] }
	end

	def list_labels
		list = [['name', 'addr']]
		@dasm.prog_binding.each { |k, v|
			list << [k, Expression[@dasm.normalize(v)]]
		}
		listwindow("list of labels", list) { |i| focus_addr i[1] }
	end

	def list_sections
		list = [['addr', 'length', 'name', 'info']]
		@dasm.section_info.each { |n,a,l,i|
			list << [Expression[a], Expression[l], n, i]
		}
		listwindow("list of sections", list) { |i| focus_addr i[0] if i[0] != '0' or @dasm.get_section_at(0) }
	end

	def list_strings
		list = [['addr', 'string']]
		nexto = 0
		@dasm.pattern_scan(/[\x20-\x7e]{6,}/m) { |o|
			if o - nexto > 0
				next unless s = @dasm.get_section_at(o)
				str = s[0].data[s[0].ptr, 1024][/[\x20-\x7e]{6,}/m]
				list << [o, str[0, 24].inspect]
				nexto = o + str.length
			end
		}
		listwindow("list of strings", list) { |i| focus_addr i[0] }
	end

	def list_xrefs(addr)
		list = [['address', 'type', 'instr']]
		@dasm.each_xref(addr) { |xr|
			next if not xr.origin
			list << [Expression[xr.origin], "#{xr.type}#{xr.len}"]
			if di = @dasm.di_at(xr.origin)
				list.last << di.instruction
			end
		}
		if list.length == 1
			messagebox "no xref to #{Expression[addr]}" if addr
		else
			listwindow("list of xrefs to #{Expression[addr]}", list) { |i| focus_addr(i[0], nil, true) }
		end
	end

	# jump to address
	def prompt_goto
		inputbox('address to go', :text => Expression[curaddr]) { |v|
			focus_addr_autocomplete(v)
		}
	end

	def prompt_backtrace
		addr = curaddr
		inputbox('expression to backtrace', :text => curview.hl_word) { |e|
			expr = IndExpression.parse_string(e)
			bd = {}
			registers = (@dasm.cpu.dbg_register_list.map { |r| r.to_s } rescue [])
			expr.externals.grep(String).each { |w|
				if registers.include? w.downcase
					bd[w] = w.downcase.to_sym
				end
			}
			expr = expr.bind(bd).reduce { |e_| e_.len ||= @dasm.cpu.size/8 if e_.kind_of? Indirection ; nil }

			log = []
			dasm.backtrace(expr, addr, :log => log)
			list = [['address', 'type', 'old value', 'value']]
			log.each { |t, *a|
				list << [Expression[a[-1]], t]
				case t
				when :start
					list.last << a[0]
				when :up
					list.pop
				when :di
					list.last << a[1] << a[0]
				when :func
					list.last << a[1] << a[0]
				when :found
					list.pop
					a[0].each { |e_| list << [nil, :found, Expression[e_]] }
				else
					list.last << a[0] << a[1..-1].inspect
				end
			}
			list_bghilight("backtrace #{expr} from #{Expression[addr]}", list) { |i|
				a = i[0].empty? ? i[2] : i[0]
				focus_addr(a, nil, true)
 			}
		}
	end

	# same as focus_addr, also understands partial label names
	# if the partial part is ambiguous, show a listwindow with all matches (if show_alt)
	def focus_addr_autocomplete(v, show_alt=true)
		if not focus_addr(v, nil, true)
			labels = @dasm.prog_binding.map { |k, vv|
 				[k, Expression[@dasm.normalize(vv)]] if k.downcase.include? v.downcase
			}.compact
			case labels.length
			when 0; focus_addr(v)
			when 1; focus_addr(labels[0][0])
			else
				if labels.all? { |k, vv| vv == labels[0][1] }
					focus_addr(labels[0][0])
				elsif show_alt
					labels.unshift ['name', 'addr']
					listwindow("list of labels", labels) { |i| focus_addr i[1] }
				end
			end
		end
	end

	# parses a C header
	def prompt_parse_c_file
		openfile('open C header') { |f|
			@dasm.parse_c_file(f) rescue messagebox("#{$!}\n#{$!.backtrace}")
		}
	end

	# run arbitrary ruby
	def prompt_run_ruby
		inputbox('ruby code to eval()') { |c| messagebox eval(c).inspect[0, 512], 'eval' }
	end

	# run ruby plugin
	def prompt_run_ruby_plugin
		openfile('ruby plugin') { |f| @dasm.load_plugin(f) }
	end

	# search for a regexp in #dasm.decoded.to_s
	def prompt_search_decoded
		inputbox('text to search in instrs (regex)') { |pat|
			re = /#{pat}/i
			found = []
			@dasm.decoded.each { |k, v|
				found << k if v.to_s =~ re
			}
			list = [['addr', 'str']] + found.map { |a| [Expression[a], @dasm.decoded[a].to_s] }
			list_bghilight("search result for /#{pat}/i", list) { |i| focus_addr i[0] }
		}
	end

	# calls the @dasm.rebase method to change the load base address of the current program
	def rebase(addr=nil)
		if not addr
			inputbox('rebase address') { |a| rebase(Integer(a)) }
		else
			na = curaddr + dasm.rebase(addr)
			gui_update
			focus_addr na
		end
	end

	# prompts for a new name for addr
	def rename_label(addr)
		old = addr
		if @dasm.prog_binding[old] or old = @dasm.get_label_at(addr)
			inputbox("new name for #{old}", :text => old) { |v|
				if v == ''
					@dasm.del_label_at(addr)
				else
					@dasm.rename_label(old, v)
				end
				gui_update
			}
		else
			inputbox("label name for #{Expression[addr]}", :text => Expression[addr]) { |v|
				next if v == ''
				@dasm.set_label_at(addr, v)
				if di = @dasm.di_at(addr)
					@dasm.split_block(di.block, di.address)
				end
				gui_update
			}
		end
	end

	# pause/play disassembler
	# returns true if playing
	# this empties @dasm.addrs_todo, the dasm may still continue to work if this msg is
	#  handled during an instr decoding/backtrace (the backtrace may generate new addrs_todo)
	# addresses in addrs_todo pointing to existing decoded instructions are left to create a prettier graph
	def playpause_dasm
		@dasm_pause ||= []
		if @dasm_pause.empty? and @dasm.addrs_todo.empty?
			true
		elsif @dasm_pause.empty?
			@dasm_pause = @dasm.addrs_todo.dup
			@dasm.addrs_todo.replace @dasm_pause.find_all { |a, *b| @dasm.decoded[@dasm.normalize(a)] }
			@dasm_pause -= @dasm.addrs_todo
			puts "dasm paused (#{@dasm_pause.length})"
		else
			@dasm.addrs_todo.concat @dasm_pause
			@dasm_pause.clear
			puts "dasm restarted (#{@dasm.addrs_todo.length})"
			start_disassemble_bg
			true
		end
	end

	# toggles <41h> vs <'A'> display
	def toggle_expr_char(o)
		@dasm.toggle_expr_char(o)
		gui_update
	end

	# toggle <401000h> vs <'sub_fancyname'> in the current instr display
	def toggle_expr_offset(o)
		@dasm.toggle_expr_offset(o)
		gui_update
	end

	def toggle_view(idx)
		default = (idx == :graph ? :listing : :graph)
		# switch to idx ; if already in idx, use default
		focus_addr(curaddr, ((curview_index == idx) ? default : idx))
	end

	# undefines the whole function body
	def undefine_function(addr, incl_subfuncs = false)
		list = []
		@dasm.each_function_block(addr, incl_subfuncs) { |b| list << b }
		list.each { |b| @dasm.undefine_from(b) }
		gui_update
	end

	def keypress_ctrl(key)
		return true if @keyboard_callback_ctrl[key] and @keyboard_callback_ctrl[key][key]
		case key
		when :enter; focus_addr_redo
		when ?o; w = toplevel ; w.promptopen if w.respond_to? :promptopen
		when ?s; w = toplevel ; w.promptsave if w.respond_to? :promptsave
		when ?r; prompt_run_ruby
		when ?C; disassemble_fast_deep(curaddr)
		when ?f; prompt_search_decoded
		else return @parent_widget ? @parent_widget.keypress_ctrl(key) : false
		end
		true
	end

	def keypress(key)
		return true if @keyboard_callback[key] and @keyboard_callback[key][key]
		case key
		when :enter; focus_addr curview.hl_word
		when :esc; focus_addr_back
		when ?/; inputbox('search word') { |w|
				next unless curview.respond_to? :hl_word
				next if w == ''
				curview.hl_word = w 
				curview.redraw
			}
		when ?b; prompt_backtrace
		when ?c; disassemble(curview.current_address)
		when ?C; disassemble_fast(curview.current_address)
		when ?d; toggle_data(curview.current_address)
		when ?f; list_functions
		when ?g; prompt_goto
		when ?l; list_labels
		when ?n; rename_label(pointed_addr)
		when ?o; toggle_expr_offset(curobj)
		when ?p; playpause_dasm
		when ?r; toggle_expr_char(curobj)
		when ?v; $VERBOSE = ! $VERBOSE ; puts "#{'not ' if not $VERBOSE}verbose"	# toggle verbose flag
		when ?x; list_xrefs(pointed_addr)
		when ?;; add_comment(curview.current_address)

		when ?\ ; toggle_view(:listing)
		when :tab; toggle_view(:decompile)
		when ?j; curview.keypress(:down)
		when ?k; curview.keypress(:up)
		else
			p key if $DEBUG
			return @parent_widget ? @parent_widget.keypress(key) : false
		end
		true
	end

	# creates a new dasm window with the same disassembler object, focus it on addr#win
	def clone_window(*focus)
		return if not popup = DasmWindow.new
		popup.display(@dasm, @entrypoints)
		w = popup.dasm_widget
		w.bg_color_callback = @bg_color_callback if bg_color_callback
		w.keyboard_callback = @keyboard_callback
		w.keyboard_callback_ctrl = @keyboard_callback_ctrl
		w.clones = @clones.concat w.clones
		w.focus_addr(*focus)
		popup
	end

	def dragdropfile(f)
		case f
		when /\.(c|h|cpp)$/; @dasm.parse_c_file(f)
		when /\.map$/; @dasm.load_map(f)
		else messagebox("unsupported file extension #{f}")
		end
	end
end

# this widget is loaded in an empty DasmWindow to handle shortcuts (open file, etc)
class NoDasmWidget < DrawableWidget
	def initialize_widget(window)
		@window = window
	end

	def paint
	end

	def keypress(key)
		case key
		when ?v; $VERBOSE = !$VERBOSE
		when ?d; $DEBUG = !$DEBUG
		end
	end

	def keypress_ctrl(key)
		case key
		when ?o; @window.promptopen
		when ?r; @window.promptruby
		end
	end

	def dragdropfile(f)
		case f
		when /\.(c|h|cpp)$/; messagebox('load a binary first')
		else @window.loadfile(f)	# TODO prompt to start debugger instead of dasm
		end
	end
end

class DasmWindow < Window
	attr_accessor :dasm_widget, :menu
	def initialize_window(title = 'metasm disassembler', dasm=nil, *ep)
		self.title = title
		@dasm_widget = nil
		if dasm
			ep = ep.first if ep.length == 1 and ep.first.kind_of? Array
			display(dasm, ep)
		else
			self.widget = NoDasmWidget.new(self)
		end
	end
	
	def widget=(w)
		super(w || NoDasmWidget.new(self))
	end

	def destroy_window
		@dasm_widget.terminate if @dasm_widget
		super()
	end

	# sets up a DisasmWidget as main widget of the window, replaces the current if it exists
	# returns the widget
	def display(dasm, ep=[])
		@dasm_widget.terminate if @dasm_widget
		@dasm_widget = DisasmWidget.new(dasm, ep)
		self.widget = @dasm_widget
		@dasm_widget.focus_addr(ep.first) if ep.first
		@dasm_widget
	end

	# returns the specified widget from the @dasm_widget (idx in :hex, :listing, :graph etc)
	def widget(idx=nil)
		idx && @dasm_widget ? @dasm_widget.view(idx) : @dasm_widget
	end

	def loadfile(path, cpu='Ia32', exefmt=nil)
		if exefmt
			exefmt = Metasm.const_get(exefmt) if exefmt.kind_of? String
		else
			exefmt = AutoExe.orshellcode { cpu = Metasm.const_get(cpu) if cpu.kind_of? String ; cpu.new }
		end

		exe = exefmt.decode_file(path) { |type, str|
			# Disassembler save file will use this callback with unhandled sections / invalid binary file path
			case type
			when 'binarypath'
				ret = nil
				openfile("please locate #{str}", :blocking => true) { |f| ret = f }
				return if not ret
				ret
			end
		}
		(@dasm_widget ? DasmWindow.new : self).display(exe.disassembler)
		exe
	end

	def promptopen(caption='chose target binary')
		openfile(caption) { |exename| loadfile(exename) ; yield self if block_given? }
	end

	def promptdebug(caption='chose target')
		l = nil
		i = inputbox(caption) { |name|
			i = nil ; l.destroy if l and not l.destroyed?
			if pr = OS.current.find_process(name)
				target = pr.debugger
			elsif name =~ /^(udp|tcp|.*\d+.*):/i	# don't match c:\kikoo, but allow 127.0.0.1 / [1:2::3]
				target = GdbRemoteDebugger.new(name)
			elsif pr = OS.current.create_process(name)
				target = pr.debugger
			else
				messagebox('no such target')
				next
			end
			DbgWindow.new(target)
			destroy if not @dasm_widget
			yield self if block_given?
		}

		# build process list in bg (exe name resolution takes a few seconds)
		list = [['pid', 'name']]
		list_pr = OS.current.list_processes
		Gui.idle_add {
			if pr = list_pr.shift
				path = pr.modules.first.path if pr.modules and pr.modules.first
				#path ||= '<unk>'	# if we can't retrieve exe name, can't debug the process
				list << [pr.pid, path] if path
				true
			elsif i
				l = listwindow('running processes', list, :noshow => true) { |e| i.text = e[0] }
				l.x += l.width
				l.show
				false
			end
		}
	end

	def promptsave
		openfile('chose save file') { |file|
			@dasm_widget.dasm.save_file(file)
		} if @dasm_widget
	end

	def promptruby
		if @dasm_widget
			@dasm_widget.prompt_run_ruby
		else
			inputbox('code to eval') { |c| messagebox eval(c).inspect[0, 512], 'eval' }
		end
	end

	def build_menu
		# TODO dynamic checkboxes (check $VERBOSE when opening the options menu to (un)set the mark)
		filemenu = new_menu

		# a fake unreferenced accel group, so that the shortcut keys appear in the menu, but the widget keypress is responsible
		# of handling them (otherwise this would take precedence and :hex couldn't get 'c' etc)
		# but ^o still works (must work even without DasmWidget loaded)

		addsubmenu(filemenu, 'OPEN', '^o') { promptopen }
		addsubmenu(filemenu, '_Debug') { promptdebug }
		addsubmenu(filemenu, 'SAVE', '^s') { promptsave }
		addsubmenu(filemenu, 'CLOSE') {
			if @dasm_widget
				@dasm_widget.terminate
				@dasm_widget = nil
				self.widget = nil
			end
		}
		addsubmenu(filemenu)

		iomenu = new_menu
		addsubmenu(iomenu, 'Load _map') {
			openfile('chose map file') { |file|
				@dasm_widget.dasm.load_map(File.read(file)) if @dasm_widget
			} if @dasm_widget
		}
		addsubmenu(iomenu, 'S_ave map') {
			savefile('chose map file') { |file|
				File.open(file, 'w') { |fd|
					fd.puts @dasm_widget.dasm.save_map
				} if @dasm_widget
			} if @dasm_widget
		}
		addsubmenu(iomenu, '_Save asm') {
			savefile('chose asm file') { |file|
				File.open(file, 'w') { |fd|
					fd.puts @dasm_widget.dasm
				} if @dasm_widget
			} if @dasm_widget
		}
		addsubmenu(iomenu, 'Save _C') {
			savefile('chose C file') { |file|
				File.open(file, 'w') { |fd|
					fd.puts @dasm_widget.dasm.c_parser
				} if @dasm_widget
			} if @dasm_widget
		}
		addsubmenu(filemenu, 'Load _C') {
			openfile('chose C file') { |file|
				@dasm_widget.dasm.parse_c(File.read(file)) if @dasm_widget
			} if @dasm_widget
		}
		addsubmenu(filemenu, '_i/o', iomenu)
		addsubmenu(filemenu)
		addsubmenu(filemenu, 'QUIT') { destroy } # post_quit_message ?

		addsubmenu(@menu, filemenu, '_File')

		actions = new_menu
		dasm = new_menu
		addsubmenu(dasm, '_Disassemble from here', 'c') { @dasm_widget.disassemble(@dasm_widget.curview.current_address) }
		addsubmenu(dasm, 'Disassemble _fast from here', 'C') { @dasm_widget.disassemble_fast(@dasm_widget.curview.current_address) }
		addsubmenu(dasm, 'Disassemble fast & dee_p from here', '^C') { @dasm_widget.disassemble_fast_deep(@dasm_widget.curview.current_address) }
		addsubmenu(actions, dasm, '_Disassemble')
		addsubmenu(actions, 'Follow', '<enter>') { @dasm_widget.focus_addr @dasm_widget.curview.hl_word }	# XXX
		addsubmenu(actions, 'Jmp back', '<esc>') { @dasm_widget.focus_addr_back }
		addsubmenu(actions, 'Undo jmp back', '^<enter>') { @dasm_widget.focus_addr_redo }
		addsubmenu(actions, 'Goto', 'g') { @dasm_widget.prompt_goto }
		addsubmenu(actions, '_Backtrace', 'b') { @dasm_widget.prompt_backtrace }
		addsubmenu(actions, 'List functions', 'f') { @dasm_widget.list_functions }
		addsubmenu(actions, 'List labels', 'l') { @dasm_widget.list_labels }
		addsubmenu(actions, 'List xrefs', 'x') { @dasm_widget.list_xrefs(@dasm_widget.pointed_addr) }
		addsubmenu(actions, 'Rebase') { @dasm_widget.rebase }
		addsubmenu(actions, 'Rename label', 'n') { @dasm_widget.rename_label(@dasm_widget.pointed_addr) }
		addsubmenu(actions, 'Decompile', '<tab>') { @dasm_widget.decompile(@dasm_widget.curview.current_address) }
		addsubmenu(actions, 'Decompile finali_ze') { @dasm_widget.dasm.decompiler.finalize ; @dasm_widget.gui_update }
		addsubmenu(actions, 'Comment', ';') { @dasm_widget.decompile(@dasm_widget.curview.current_address) }
		addsubmenu(actions, '_Undefine') { @dasm_widget.dasm.undefine_from(@dasm_widget.curview.current_address) ; @dasm_widget.gui_update }
		addsubmenu(actions, 'Unde_fine function') { @dasm_widget.undefine_function(@dasm_widget.curview.current_address) }
		addsubmenu(actions, 'Undefine function & _subfuncs') { @dasm_widget.undefine_function(@dasm_widget.curview.current_address, true) }
		addsubmenu(actions, 'Data', 'd') { @dasm_widget.toggle_data(@dasm_widget.curview.current_address) }
		addsubmenu(actions, 'Pause dasm', 'p', :check) { |ck| !@dasm_widget.playpause_dasm }
		addsubmenu(actions, 'Run ruby snippet', '^r') { promptruby }
		addsubmenu(actions, 'Run _ruby plugin') { @dasm_widget.prompt_run_ruby_plugin }

		addsubmenu(@menu, actions, '_Actions')

		options = new_menu
		addsubmenu(options, '_Verbose', :check, $VERBOSE, 'v') { |ck| $VERBOSE = ck }
		addsubmenu(options, 'Debu_g', :check, $DEBUG) { |ck| $DEBUG = ck }
		addsubmenu(options, 'Debug _backtrace', :check) { |ck| @dasm_widget.dasm.debug_backtrace = ck if @dasm_widget }
		addsubmenu(options, 'Backtrace li_mit') {
			inputbox('max blocks to backtrace', :text => @dasm_widget.dasm.backtrace_maxblocks) { |target|
				@dasm_widget.dasm.backtrace_maxblocks = Integer(target) if not target.empty?
			} if @dasm_widget
		}
		addsubmenu(options, 'Backtrace _limit (data)') {
			inputbox('max blocks to backtrace data (-1 to never start)',
					:text => @dasm_widget.dasm.backtrace_maxblocks_data) { |target|
				@dasm_widget.dasm.backtrace_maxblocks_data = Integer(target) if not target.empty?
			} if @dasm_widget
		}
		addsubmenu(options)
		addsubmenu(options, 'Forbid decompile _types', :check) { |ck| @dasm_widget.dasm.decompiler.forbid_decompile_types = ck }
		addsubmenu(options, 'Forbid decompile _if/while', :check) { |ck| @dasm_widget.dasm.decompiler.forbid_decompile_ifwhile = ck }
		addsubmenu(options, 'Forbid decomp _optimize', :check) { |ck| @dasm_widget.dasm.decompiler.forbid_optimize_code = ck }
		addsubmenu(options, 'Forbid decomp optim_data', :check) { |ck| @dasm_widget.dasm.decompiler.forbid_optimize_dataflow = ck }
		addsubmenu(options, 'Forbid decomp optimlab_els', :check) { |ck| @dasm_widget.dasm.decompiler.forbid_optimize_labels = ck }
		addsubmenu(options, 'Decompiler _recurse', :check, true) { |ck| @dasm_widget.dasm.decompiler.recurse = (ck ? 1/0.0 : 1) ; ck }	# XXX race if changed while decompiling
		# TODO CPU type, size, endian...
		# factorize headers

		addsubmenu(@menu, options, '_Options')

		views = new_menu
		addsubmenu(views, 'Dis_assembly') { @dasm_widget.focus_addr(@dasm_widget.curaddr, :listing) }
		addsubmenu(views, '_Graph') { @dasm_widget.focus_addr(@dasm_widget.curaddr, :graph) }
		addsubmenu(views, 'De_compiled') { @dasm_widget.focus_addr(@dasm_widget.curaddr, :decompile) }
		addsubmenu(views, 'Raw _opcodes') { @dasm_widget.focus_addr(@dasm_widget.curaddr, :opcodes) }
		addsubmenu(views, '_Hex') { @dasm_widget.focus_addr(@dasm_widget.curaddr, :hex) }
		addsubmenu(views, 'Co_verage') { @dasm_widget.focus_addr(@dasm_widget.curaddr, :coverage) }
		addsubmenu(views, '_Sections') { @dasm_widget.list_sections }
		addsubmenu(views, 'St_rings') { @dasm_widget.list_strings }

		addsubmenu(@menu, views, '_Views')
	end
end
end
end