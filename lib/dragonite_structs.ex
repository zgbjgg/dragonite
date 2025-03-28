defmodule DragoniteEDI.ST do
  @moduledoc """
  Struct defined for ST node at EDI message. ST node indicates the start of a
  segment.

  `fields` - an enum of string fields.

  `values` - an enum of enums where each enum contains strings.
  """
  defstruct fields: [], values: []
end

defmodule DragoniteEDI.SE do
  @moduledoc """
  Struct defined for SE node at EDI message. SE node indicates the end of a
  segment.

  `fields` -  an enum of string fields.
  """
  defstruct fields: []
end

defmodule DragoniteEDI.GS do
  @moduledoc """
  Struct defined for GS node at EDI message. GS node indicates the start
  of a functional group containing multiple segments.

  `fields` - an enum of string fields.

  `st` - an enumerable of `DragoniteEDI.ST` nodes. See `DragoniteEDI.ST` for more info.

  `se` - a node of `DragoniteEDI.SE`. See `DragoniteEDI.SE` for more info.
  """
  defstruct fields: [], st: nil, se: nil
end

defmodule DragoniteEDI.GE do
  @moduledoc """
  Struct defined for GE node at EDI message. GE node indicates the end of
  a functional group.

  `fields` - an enum of string fields.
  """
  defstruct fields: []
end

defmodule DragoniteEDI.ISA do
  @moduledoc """
  Struct defined for ISA node at EDI message. ISA node indicates the start of
  a transaction containing multiple functional groups.

  `fields` - an enum of string fields.

  `gs` - an enum of `DragoniteEDI.GS` nodes. See `DragoniteEDI.GS` for more info.

  `ge` - a node of `DragoniteEDI.GE`. See `DragoniteEDI.GE` for more info.
  """
  defstruct fields: [], gs: nil, ge: nil
end

defmodule DragoniteEDI.IEA do
  @moduledoc """
  Struct defined for IEA node at EDI message. IEA node indicates the end of
  a transaction.

  `fields` - an enum of string fields.
  """
  defstruct fields: []
end

defmodule DragoniteEDI.Message do
  @moduledoc """
  Struct defined for Edi message. EDI message contains mainly two nodes
  composed by `DragoniteEDI.ISA` and `DragoniteEDI.IEA`. See `DragoniteEDI.ISA`, `DragoniteEDI.IEA`
  for more info.

  An extra data is included `sts`, because a single message will be splitted in multiple
  messages, containing multiple STs, then to validate ST length, we need store the original
  ST length value, instead of take from message.

  STs is automatic filled and should not be used to handle other data.

  `isa` - a node of `DragoniteEDI.ISA`.

  `iea` - a node of `DragoniteEDI.IEA`

  `sts` - number of STS
  """
  defstruct isa: nil, iea: nil, sts: 0
end
