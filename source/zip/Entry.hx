package zip;

import haxe.io.Bytes;

class Entry implements IEntry
{
	public var version:{needed:Int, made:Int};

	public var flag:Int;

	/**
	 * The general
	 */
	@:allow(Zip)
	var decriptor:{size:{uncompressed:Int, compressed:Int}, crc32:Int};

	/**
	 * The name of the entry.
	 */
	public var name:String;

	/**
	 * The date which this file was made in. (MS-DOS format).
	 */
	public var date:Date;

	/**
	 * The compression which the Entry is compressed in.  
	 */
	public var compressionMethod:CompressionMethod;

	/**
	 * The data of the Entry.
	 */
	public var data:haxe.io.Bytes;

	/**
	 * I genuinely don't know how to parse this.
	 * if you have an idea of how it should work, please give me documentation and please explain to me.
	 */
	public var extraFields:Array<{tag:Int, bytes:Bytes}>;

	public var size(get, null):Int;

	public var entries:Null<Array<Entry>>;

	@:allow(Zip)
	function new()
	{
		decriptor = {size: {uncompressed: 0, compressed: 0}, crc32: 0};
		extraFields = [];
		compressionMethod = NONE;
		date = Date.now();
		version = {made: 0, needed: 0};
	}

	function get_size():Int
	{
		return (compressionMethod == NONE) ? decriptor.size.uncompressed : decriptor.size.compressed;
	}
}

enum abstract CompressionMethod(Int) from Int to Int
{
	var NONE = 0;
	var SHRUNK = 1;
	var DEFLATE = 8;
	var DEFLATE64 = 9;

	function toString()
	{
		return switch (this)
		{
			case NONE: "NONE";
			case SHRUNK: "SHRUNK";
			case DEFLATE: "DEFLATE";
			case DEFLATE64: "DEFLATE64";
			default: null;
		}
	}
}

interface IEntry
{
	/**
	 * The name of the file.
	 */
	var name:String;

	var size(get, null):Int;

	var date:Date;

	var version:{made:Int, needed:Int};

	var flag:Int;

	var compressionMethod:CompressionMethod;

	private var decriptor:{crc32:Int, size:{compressed:Int, uncompressed:Int}};

	var extraFields:Array<{tag:Int, bytes:Bytes}>;
}
