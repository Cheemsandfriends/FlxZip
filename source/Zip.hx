/*
 * Apache License, Version 2.0
 *
 * Copyright (c) 2022 CheemsAndFriends
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 *     http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.zip.Reader;
import zip.CentralEntry;
import zip.Entry;

class Zip
{
	@:noCompletion
	var input:BytesInput;

	var entries:Map<String, CentralEntry>;

	var _cacheEntry:Map<String, Entry>;

	public var comment:String;

	public var size:Int;

	public function new(bytes:Bytes)
	{
		input = new BytesInput(bytes);
		entries = [];
		_cacheEntry = [];
	}

	public function read()
	{
		@:privateAccess
		var bytes = input.b;
		if (bytes == null)
		{
			throw "Bytes in Zip are null!";
		}

		input.position = input.length - 1;
		while (true)
		{
			input.position--;
			if (input.readByte() == 0)
			{
				input.position -= 22;
				break;
			}
			input.position--;
		}

		if (input.readInt32() != 0x06054b50)
			throw 'Signature for the end of the central directory isn\'t valid!';
		var diskNum = input.readUInt16();
		var centralPos = input.readUInt16();
		var numEntries = input.readUInt16();
		var totalEntries = input.readUInt16();
		size = input.readInt32();
		var location = input.readInt32();
		comment = input.read(input.readUInt16()).toString();
		input.position = location;
		for (number in 0...numEntries)
		{
			if (input.readInt32() != 0x02014b50)
				throw "Entry not valid!";
			var entry = new CentralEntry();
			entry.version = {made: input.readInt16(), needed: input.readInt16()};
			entry.flag = input.readUInt16();

			entry.compressionMethod = input.readUInt16();

			entry.date = readZipDate();
			entry.decriptor.crc32 = input.readInt32();
			entry.decriptor.size = {compressed: input.readInt32(), uncompressed: input.readInt32()};
			var lenName = input.readUInt16();
			var lenField = input.readUInt16();
			var lenComment = input.readUInt16();
			var filePos = input.readUInt16();
			entry.attributes = {internal: input.readUInt16(), external: input.readInt32()};
			entry.offset = input.readInt32();
			entry.name = input.read(lenName).toString();

			var pos = input.position + lenField;
			while (input.position < pos)
			{
				var tag = input.readUInt16();
				var len = input.readUInt16();
				entry.extraFields.push({tag: tag, bytes: input.read(len)});
			}
			if (lenComment != 0)
				entry.comment = input.read(lenComment).toString();
			if (StringTools.contains(entry.name, "/"))
			{
				if (entry.name.charAt(entry.name.length - 1) == "/")
				{
					entry.entries = [];
				}
				else
				{
					var folder:String = "";
					for (i in 0...entry.name.length)
					{
						folder += entry.name.charAt(i);
					}
					var len = folder.length;
					for (i in 0...len)
					{
						if (folder.charAt(len - 1 - i) == "/")
							break;
						else
						{
							folder = folder.substring(0, len - 1 - i);
						}
					}
					var folder = entries.get(folder);
					if (folder.entries == null)
						entries = [];
					folder.entries.push(entry);
				}
			}
			entries.set(entry.name, entry);
		}
	}

	public function getEntries(?folder:String)
	{
		var array = [];

		for (entry in getEntryNames(folder))
		{
			array.push(getEntry(entry));
		}

		return array;
	}

	public function getEntryNames(?folder:String)
	{
		if (folder != null && StringTools.trim(folder) != "")
		{
			folder = StringTools.replace(folder, "\\", "/");
			if (!StringTools.endsWith(StringTools.trim(folder), "/"))
				folder += "/";
		}
		var array = [];
		var iter = (folder != null && StringTools.trim(folder) != "") ? getEntry(folder).entries.iterator() : entries.iterator();

		for (entry in iter)
		{
			var filName = entry.name.substring((folder != null) ? folder.length : 0, entry.name.length);
			if (StringTools.contains(filName, "/") && !StringTools.endsWith(filName, "/"))
				continue;
			array.push(entry.name);
		}
		return array;
	}

	public function getEntry(name:String)
	{
		return entries.get(name);
	}

	public function extract(name:String)
	{
		return _extract([getEntry(name)])[0];
	}

	var _pref:String = "";

	function _extract(entries:Array<CentralEntry>)
	{
		var array = [];
		for (centralEntry in entries)
		{
			if (centralEntry == null)
				continue;
			if (_pref == "")
			{
				var arr = centralEntry.name.split("/");
				arr.pop();
				_pref = arr.join("/");
			}
			if (_cacheEntry.exists(_pref + centralEntry.name))
			{
				array.push(_cacheEntry.get(_pref + centralEntry.name));
				continue;
			}
			input.position = centralEntry.offset;
			if (input.readInt32() != 0x04034b50)
				throw "the Entry is not valid!";
			var entry = new Entry();
			entry.version.needed = input.readUInt16();
			entry.flag = input.readUInt16();
			entry.compressionMethod = input.readUInt16();
			entry.date = readZipDate();
			entry.decriptor.crc32 = input.readInt32();
			entry.decriptor.size.compressed = input.readInt32();
			entry.decriptor.size.uncompressed = input.readInt32();
			var lenName = input.readUInt16();
			var lenExtra = input.readUInt16();
			entry.name = input.read(lenName).toString();

			var pos = input.position + lenExtra;
			while (input.position < pos)
			{
				var tag = input.readUInt16();
				var len = input.readUInt16();
				entry.extraFields.push({tag: tag, bytes: input.read(len)});
			}
			if (!StringTools.endsWith(entry.name, "/"))
				entry.data = input.read(entry.size);
			if (centralEntry.entries != null)
			{
				_pref += '${entry.name}/';
				entry.entries = _extract(centralEntry.entries);
			}
			_cacheEntry.set(_pref + entry.name, entry);
			array.push(entry);
		}
		_pref = "";
		return array;
	}

	public function unzip(entry:Entry)
	{
		return _unzip([entry])[0];
	}

	@:noCompletion
	function _unzip(entries:Array<Entry>)
	{
		var c = new haxe.zip.Uncompress(-15);
		for (entry in entries)
		{
			if (entry == null || entry.compressionMethod == NONE || entry.data == null || entry.data.length == 0)
				continue;
			if (_pref == "")
			{
				var arr = entry.name.split("/");
				arr.pop();
				_pref = arr.join("/");
			}
			if (entry.size != 0)
			{
				var s = haxe.io.Bytes.alloc(entry.decriptor.size.uncompressed);
				var r = c.execute(entry.data, 0, s, 0);
				if (!r.done || r.read != entry.data.length || r.write != entry.decriptor.size.uncompressed)
					throw "Invalid compressed data for " + entry.name;
				getEntry(entry.name).compressionMethod = entry.compressionMethod = NONE;
				entry.data = s;
			}
			if (entry.entries != null)
			{
				_pref += '${entry.name}/';
				entry.entries = _unzip(entry.entries);
			}
			_cacheEntry.set(_pref + entry.name, entry);
		}
		c.close();
		_pref = "";
		return entries;
	}

	// stolen from haxe.zip.Reader cos I dont wanna make it myself and its opensource so  ¯\_(ツ)_/¯
	function readZipDate()
	{
		var t = input.readUInt16();
		var hour = (t >> 11) & 31;
		var min = (t >> 5) & 63;
		var sec = t & 31;
		var d = input.readUInt16();
		var year = d >> 9;
		var month = (d >> 5) & 15;
		var day = d & 31;
		return new Date(year + 1980, month - 1, day, hour, min, sec << 1);
	}
}
