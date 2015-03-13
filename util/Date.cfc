component {
	public com.ncr.util.Date function init() { return this; }
	
	public string function getDateTime(date) {
		local.date = ((structKeyExists(arguments, 'date')) ? arguments.date : this.getNow());
		
		return '#dateFormat(local.date, "yyyy-mm-dd")# #timeFormat(local.date, "HH:MM:SS")#';
	}
	
	public date function getNow() {
		local.query = application.query.run({
			datasource = application.dsn.default,
			sql = "select now() as currentDate;"
		});
		return local.query.getResult().currentDate[1];
	}
	
	public any function getTime() {
		return dateConvert('local2utc', this.getNow()).getTime();
	}
}