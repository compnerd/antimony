
The following variables are pre-defined built-in values for defining the build:

<dl>
  <dt>antimony_version</dt>
  <dd>
  <b>[integer]</B> The version of antimony.<br/>
  Encodes the antimony version as a integral representation using 2-digits per component and encoding the version as $major * 10000 + minor * 100 + patch$.
  </dd>
  <dt>build_cpu</dt>
  <dd>
  <b>[string]</b> The processor architecture for the build machine.<br/>
  This encodes the CPU identifier for the build machine. The value is spelt according to the Swift `arch` conditional function parameter.
  </dd>
  <dt>build_os</dt>
  <dd>
  <b>[string]</b> The operating system for the build machine.<br/>
  This encodes the OS identifier for the build machine. The value is spelt according to teh Swift `os` conditional function parameter but in lowercase.
  </dd>
  <dt>host_cpu</dt>
  <dd>
  <b>[string]</b> The processor architecture for the host machine.<br/>
  This encodes the CPU identifier for the host machine where the binaries will run. The value is spelt according to the Swift `arch` conditional function parameter.
  </dd>
  <dt>host_os</dt>
  <dd>
  <b>[string]</b> The operating system for the host machine.<br/>
  This encodes the OS identifier for the host machine where the binaries will run. The value is spelt according to the Swift `arch` conditional function parameter.
  </dd>
</dl>
