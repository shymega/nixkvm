{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, cryptography
, python-dateutil
, six
, pbr
}:

buildPythonPackage rec {
  pname = "pyghmi";
  version = "1.5.69";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-+qNJWylZx22gBjqE82cNEchwUQUPau+4uGd7dK3wWUY=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    cryptography
    python-dateutil
    six
    pbr
  ];

  pythonImportsCheck = [ "pyghmi" ];

  meta = with lib; {
    description = "Python General Hardware Management Initiative (IPMI and others";
    homepage = "https://pypi.org/project/pyghmi/";
    license = licenses.asl20;
    maintainers = with maintainers; [ matthewcroughan ];
  };
}
