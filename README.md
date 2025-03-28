# dragonite
Dragonite - Fast, reliable and configurable EDI parser (encode &amp; decode), seeker &amp; rule runner.

### Decoding

To decode a message, use the `decode/1` function, providing a string as argument. The decode function
tries to decode the message into an `%DragoniteEDI.Message{}` struct and raises an error if the message provided
is not a valid message. To decode the parser follow the next rules:

* Must start with ISA struct.

* Must end with IEA struct.

* Function groups start with GS and end with GE.

* Segments start with ST and end with SE.

* Separator for elements is `~`

* Separator for elements into fields is `*`

This is a single example of an EDI message:

```elixir
iex(1)> msg = "ISA*00* *00* *32*0000*32*0000 *121206*1142*U*00601*000000003*1*T*>~" <>
"GS*SM*300237446*351538247*20121206*1142*3*X*006010~ST*204*000000001~B2**BWEM**317749**CC*L~" <>
"B2A*00*FR~L11*SMC LTL Fuel*XX7*Fuel Schedule: SMC LTL Fuel~L11*104*ZZ*Total Distance:104~G6" <>
"2*64*20121206*1*1244*LT~AT5*400**Transport~RTT*FC*550~C3*USD~N1*BT*Pokemon GO*93*2649" <>
"~N3*19661 Brownstown Center Dr*Suite 600~N4*Brownstown*MI*48183-1679*USA~G61*LG*Contact Phone" <>
"*TE*000-000-000 ext 3~G61*LG*Contact Mobile*CP*000-000-0000~G61*LG*Contact Email*EM*" <>
"dratini@pokemon.com~N7**Unknown*********53****0636*****110*98~S5*0*LD~L11*602465*SI~" <>
"G62*69*20120810*U*1600*LT~N1*SH*POKEMON GO*93*5715~N3*603 7th St~N4*Pokemon*MI*49601-1344*" <>
"USA~G61*LG*Contact Phone*TE*000-000-0000 ext 1357~G61*LG*Contact Email*EM*dratini@pokemon.com" <>
"~N1*CN*ABC Undercar Products Group*93*9889~N3*4247 Paleta Town SE~N4*Wyoming*MI*49508-3400*USA~N1*" <>
"SF*AVON AUTOMOTIVE*93*5715~N3*603 7th St~N4*Pokemon*MI*49601-1344*USA~G61*LG*Contact Phone*TE*" <>
"000-000-0000 ext 1357~G61*LG*Contact Email*EM*dratini@pokemon.com~LAD*PLT****L**S1*264" <>
"*****Freight All Kinds~L5*1**60*N~S5*1*UL~L11*602465*SI~G62*69*20120813*U*1600*LT~N1*SH*POKEMON" <>
" GO*93*5715~N3*603 7th St~N4*Pokemon*MI*49601-1344*USA~G61*LG*Contact Phone*TE*000-000" <>
"-0000 ext 1357~G61*LG*Contact Email*EM*dratini@pokemon.com~N1*CN*ABC " <>
"Products Group*93*9889~N3*4247 Paleta Town SE~N4*Wyoming*MI*49508-3400*USA~N1*ST*ABC " <>
" Products Group*93*9889~N3*4247 Paleta Town SE~N4*Wyoming*MI*49508-3400*USA~LAD*PLT" <>
"****L**S1*264*****Freight All Kinds~L5*1**60*N~SE*51*000000001~GE*1*3~IEA*1*000000003"
```

Now to decode the above message just call to `decode/1`:

```elixir
iex(2)> Dragonite.Parser.decode msg
```

The response (if valid) will be an `%DragoniteEDI.Message{}` struct containing all elements considered from parsing
rules. New rules can de added if nedeed.

### Decoding multiple STs

Sometimes the incoming messages will contain multiple ST, this means that multiple messages are sent once a time.

To support this, the decode/1 returns a list of messages instead a single response (even if only 1).

### Encoding

To encode a message use the `encode/1` function, providing a `DragoniteEDI.Message{}` as argument. The encode function
tries to encode the struct as a string message and raises an errir if the message provided is not a valid message. To encode
a message:

```elixir
iex(1)> Dragonite.Parser.encode %DragoniteEDI.Message{}
```

The response is a single string as an original EDI message.

### Verification

By default `decode/1` verifies the struct and return `{:ok, %DragoniteEDI.Message{}}` or `{:error, error}` where
error will describe the missing or incomplete struct. Missing or incomplete structs are marked when sub-structs
are nil or empty lists.

Validation can be skipped using `verify: false` when calling `decode/2` using opts (2nd argument) as keywords.

By default `encode/1` verifies the struct of edi message, this is mandatory.

### Rules

A single message can be passed (after parsed) for a set of rules to check if passed the criteria
or not.

The rules criteria are defined in a single YML file (see Config for more info).

To check if a message pass the criteria:

```elixir
iex(1)> Dragonite.Parser.to_rules %DragoniteEDI.Message{}, 204
```

If passed the struct is returned, otherwise an error is returned.

### Seek

Seek allows search in values of ST segment, match criteria and return values based on custom functions
provided as a part of seek process. Seek process needs the values (that can be extracted using `struct_at/3`),
the matching criteria, the values to return and a fn with two args, the first one is the resulting of matching
criteria and the second one the return data.

### Rules (YML file)

To configure the rules:

```elixir
config :dragonite, rules_file: "./rules.yml"
```

The rules have a defined structure and must be placed into an available directory, please check
priv directory to know how config for YML is used, the next is a single example of how
YML structure works:

```yml
- isa:
   04: "$edi_customer.edi_provider_id" ### ISA at position 04 MUST match with edi_provider_id value at database
   05: "08" ### ISA at position 05 MUST match 08 string.
   06:
       - {el: "gs", value: "02"} ### ISA at position 05 MUST have same value in GS at position 02
   15:
       - "P" ### ISA at position 15 MUST match P or T string, other value is not valid.
       - "T"
   16:
       - {el: "st", value: "$length"} ### ISA at position 16 should contains the length of ST elements, if ST elements are 6 this position MUST have 6.
