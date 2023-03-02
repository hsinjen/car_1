class User {
  String _userId = '';
  String _userName = '';
  String _deptId = '';
  String _deptName = '';
  String _jobId = '';
  String _jobName = '';
  String _authorityId = '';
  String _authorityName = '';
  String _email = '';
  //==================================================
  String get userId => _userId;
  set setUserId(String value) => _userId = value;
  
  String get userName => _userName;
  set setUserName(String value) => _userName = value;

  String get deptId => _deptId;
  set setDeptId(String value) => _deptId = value;

  String get deptName => _deptName;
  set setDeptName(String value) => _deptName = value;

  String get jobId => _jobId;
  set setJobId(String value) => _jobId = value;

  String get jobName => _jobName;
  set setJobName(String value) => _jobName = value;

  String get authorityId => _authorityId;
  set setAuthorityId(String value)=> _authorityId=value;

  String get authorityName => _authorityName;
  set setAuthorityName(String value)=> _authorityName = value;

  String get email=> _email;
  set setEmail(String value) => _email =value;
}
