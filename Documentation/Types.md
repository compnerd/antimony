
The BUILD language is dynamically typed. The following types are defined within
the language:

<dl>
 <dt>boolean</dt>
 <dd>
 Booleans use the reserved keywords `true` and `false` as boolean identifiers.
 The boolean type is strongly typed and is not implicitly casted between
 integeral and boolean types.
 </dd>
 <dt>integer</dt>
 <dd>
 Integers are always 64-bit signed values. Integers are always written as
 decimal values.
 </dd>
 <dt>string</dt>
 <dd>
 Strings are encoded as UTF-8 values, irrespective of the OS's preferred
 encoding. When interacting with the filesystem on Windows, the strings will be
 re-encoded to UTF-16.
 </dd>
 <dt>list</dt>
 <dd>
 Lists are arbitrary length, ordered lists of values. Lists are indexed using
 0-based indicies and are mutable.
 </dd>
 <dt>scope</dt>
 <dd>
 Scopes are lexical scoping which can be used for associating keys with values
 within the region. Scopes are used to bound the lifetime of variables within
 the body of a function call or template evaluation.
 </dd>
</dl>
