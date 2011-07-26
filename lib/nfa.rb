class Nfa
  require 'set'
  
  attr_reader :alphabet, 
              :states, 
              :transitions, 
              :start_state, 
              :accept_states, 
              :current_states
  
  def initialize rules
    # this transform could probably be split out
    rules = rules.to_s if rules.is_a? Nfa
    rules = rules.split if rules.is_a? String
    rules = rules.inject({}) do |h, rule|
      key, value = rule.chomp.split ':'
      value = '' if value.nil?
      case key
      when 'T'
        h[key] ||= []
        h[key] << value.split(',')
      when 'S'
        h[key] = value
      else # A, Q, F
        h[key] = value.split(',').to_set
      end
      h
    end
    
    # these initializations and checks could also be split out
    @states = rules['Q']
    raise 'no states' if @states.empty?
    
    @alphabet = rules['A']
    raise 'no alphabet' if @alphabet.empty?
    
    @transitions = @states.inject({}) do |h, state|
      h[state] = {}
      h
    end
    rules['T'].each do |transition|
      state, input, next_state = transition
      raise "invalid state in transition: #{state}" if not @states.member? state
      raise "invalid input in transition: #{input}" if not @alphabet.member? input and input != 'e'
      @transitions[state][input] ||= Set.new
      @transitions[state][input] << next_state
    end
    
    @start_state = rules['S']
    raise "invalid start state: #{@start_state}" if not @states.member? @start_state
    
    @accept_states = rules['F']
    @accept_states.each do |state|
      raise "invalid accept state: #{state}" if not @states.member? state
    end
    
    reset
  end
  
  def reset
    @current_states = [ @start_state ].to_set
    read_empty
  end
  
  def read_input input
    unless input == 'e'
      @current_states = next_states input
    end
    read_empty
  end
  
  def read_empty
    prev_states = @current_states
    @current_states |= next_states 'e'
    if @current_states.size > prev_states.size
      read_empty
    end
  end
  
  def accept? inputs=nil
    unless inputs.nil?
      reset
      inputs = inputs.split ',' if inputs.is_a? String
      inputs.each do |input|
        read_input input.chomp
      end
    end
    @current_states.any? { |q| @accept_states.member? q }
  end
  
  def next_states input
    @current_states \
      .reject { |state| @transitions[state][input].nil? } \
      .map { |state| @transitions[state][input] } \
      .to_set.flatten
  end
  
  def to_s
    s = "A:#{@alphabet.sort.join ','}\n"
    s += "Q:#{@states.sort.join ','}\n"
    @transitions.keys.each do |state|
      @transitions[state].keys.each do |input|
        @transitions[state][input].each do |next_state|
          s += "T:#{state},#{input},#{next_state}\n"
        end
      end
    end
    s += "S:#{start_state}\n"
    s += "F:#{@accept_states.sort.join ','}\n"
  end
end
