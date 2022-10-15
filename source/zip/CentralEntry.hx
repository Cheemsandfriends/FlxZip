package zip;

import haxe.io.Bytes;
import zip.Entry;

/**
 * # Description
 * `CentralEntry` is an extension of Entry which `CentralDirectory` uses
 */
class CentralEntry implements IEntry
{
	public var name:String;

	public var date:Date;

	public var compressionMethod:CompressionMethod;

	/**
	 * The comment of the entry.
	 */
	public var comment:String;

	@:allow(Zip)
	/**
	 * The offset where the actual entry is positioned. see `zip.Entry`
	 */
	var offset:Int;

	public var version:{needed:Int, made:Int};
	public var flag:Int;

	@:allow(Zip)
	var decriptor:{size:{uncompressed:Int, compressed:Int}, crc32:Int};

	public var extraFields:Array<{tag:Int, bytes:Bytes}>;

	public var attributes:{internal:Int, external:Int};

	public var entries:Null<Array<CentralEntry>>;
	public var size(get, null):Int;

	@:allow(Zip)
	function new()
	{
		decriptor = {size: {uncompressed: 0, compressed: 0}, crc32: 0};
		extraFields = [];
		attributes = {internal: 0, external: 0};
		compressionMethod = NONE;
		date = Date.now();
		version = {made: 0, needed: 0};
	}

	function get_size():Int
	{
		return (compressionMethod == NONE) ? decriptor.size.uncompressed : decriptor.size.compressed;
	}
}
