require 'set'

class WeightedGraph

  # Take a weighted graph of the form {['NODEA','NODEB']=>weight} where weight
  # is anything supporting '<=>' and '+' methods
  def initialize(graph)
    @graph = graph
    make_adjgraph
  end

  # Turn graph into adjacency graph of the form {"NODEA"=>{"NODEB"=>weight,...}}
  def make_adjgraph
    @adjgraph = {}
    @graph.keys.each do |k|
      node1,node2 = k
      weight = @graph[k]
      @adjgraph[node1] ||= {}
      @adjgraph[node1][node2] = weight
      @adjgraph[node2] ||= {}
      @adjgraph[node2][node1] = weight
    end
  end
end

module Dijkstra

  class State < Struct.new(:node, :via, :dist)
    INF=2**63-1
  end

  class WorkingQueue
    def initialize
      @list = []
    end

    def put(state)
      # update if preexisting and smaller distance
      existing = @list.find{ |n| n.node == state.node }
      if existing
        if existing.dist > state.dist
          existing.via = state.via
          existing.dist = state.dist
        else
          return # bogus path, longer than prev seen
        end
      else
        # otherwise add fresh
        @list.push(state)
      end
      # list must remain sorted by distance
      @list.sort!{ |a,b| a.dist <=> b.dist }
    end

    def get
      @list.shift
    end

    def size
      @list.size
    end
  end

  class CompleteQueue
    def initialize
      @list = []
    end
    def put(state)
      @list.push(state)
    end
    def find(node)
      @list.find { |state| state.node == node }
    end
    def include?(node)
      find(node) != nil
    end
  end

  # Returns [shortest_path_cost, [start,...,finish]] or nil if no path exists
  def dijkstra(start, finish)
    # Initialize the data structures
    complete = CompleteQueue.new
    current = WorkingQueue.new
    current.put(State.new(start, nil, 0))
    # Start the iteration
    end_state = nil
    while current.size > 0 and !end_state
      # grab the highest priority path seen so far
      state = current.get()
      # if 'finish' is the top of the priority queue, it is the best path
      if state.node == finish
        end_state = state
        break
      end
      # add all subpaths to the queue
      neighbors = @adjgraph[state.node].keys
      neighbors.each do |neighbor|
        if !complete.include?(neighbor)
          newstate = State.new(neighbor,state.node,state.dist + @adjgraph[state.node][neighbor])
          current.put(newstate)
        end
      end
      complete.put(state)
    end
    # If end_state is not set, no path exists
    return nil if not end_state
    # reconstruct path from the state nodes
    cost = end_state.dist
    path = []
    state = end_state
    while state
      path << state.node
      state = complete.find(state.via)
    end
    [cost, path.reverse]
  end

end

ex_graph = {
  ['START','A'] => 7,
  ['START','B'] => 2,
  ['START','C'] => 3,
  ['A','B'] => 3,
  ['A','D'] => 4,
  ['B','D'] => 4,
  ['B','H'] => 1,
  ['C','L'] => 2,
  ['D','F'] => 5,
  ['F','H'] => 3,
  ['G','H'] => 2,
  ['G','END'] => 2,
  ['I','J'] => 6,
  ['I','K'] => 4,
  ['I','L'] => 4,
  ['J','K'] => 4,
  ['J','L'] => 4,
  ['K','END'] => 5
}

graph = WeightedGraph.new(ex_graph)
graph.extend(Dijkstra)
res = graph.dijkstra('START','END')

puts "Shortest path is #{res[0]} via #{res[1].join(' -> ')}"
