defmodule CHAT.Server do
  @moduledoc """
  The `CHAT.Server` is a ring node implemented as `:n2o_pi`
  worker that handle all the incoming requests though hash function and
  implements RPC over MQ pattern. It suports both SYN and GPROC message buses (QoS=0). 
  """
  use N2O, with: [:n2o, :kvs]
  require CHAT

  @doc """
  N2O protocol implementation (server part).
  """
  def info(CHAT."Cut"(id: id), r, cx(session: from) = s) do
    KVS.cut('/chat/' ++ from, id)
    {:reply, {:default, CHAT."Ack"(lex: id)}, r, s}
  end

  def info(CHAT."Pub"(key: id, adr: CHAT."Adr"(dst: {:p2p, CHAT."P2P"(dst: to)})) = msg, r, s) do
    key = '/chat/' ++ to
    KVS.append(msg, key)
    N2O.send({:client, key}, {:forward, msg})
    {:reply, {:binary, CHAT."Ack"(lex: id)}, r, s}
  end

  def info(msg, r, s), do: {:unknown, msg, r, s}
end
