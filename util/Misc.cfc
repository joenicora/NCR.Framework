component {

	public com.ncr.util.Misc function init() {
		return this;
	}
	
	public numeric function generateId() {
		application.seed++;
		
		return 'ncr-' & application.seed;
	}
}