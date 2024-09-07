@tool
extends EditorPlugin
# CREDITS FOR IDEA AND GENERAL CODE STRUCTURE: https://github.com/meemknight/safeSave

# TODO: figure out how to use ResourceLoader instead of FileAccess
# TODO: change the checksum size back to 4 (error cause of signed and unsigned)
#		OR change the hash to 64 bit version (fails cause constatn is unsigned int size)
# TODO: rewrite using GDNative to C++ maybe

# Enable the plugin to be used as a library
class_name SafeSave

const checkSumSize = 8

static func read_entire_file_with_checksum(filePath: String) -> PackedByteArray:
	var file := FileAccess.open(filePath, FileAccess.READ)

	if not file:
		#return ERR_FILE_CANT_OPEN
		return PackedByteArray()
	
	var size_with_checksum: int = file.get_length()
	
	var data : PackedByteArray = PackedByteArray(file.get_buffer(size_with_checksum - checkSumSize))
	file.seek_end(-checkSumSize)
	var checksum : int = file.get_64()
	
		
	var test_check := fnv_hash_1a_32(data)
	
	file.close()
	if test_check != checksum:
		# return ERR_FILE_CORRUPT
		push_warning("hash didn't match!")
		return PackedByteArray()
		
	return data

static func write_entire_file_with_checksum(filePath: String, data: PackedByteArray) -> Error:
	var file := FileAccess.open(filePath, FileAccess.WRITE)
	if not file:
		return ERR_FILE_CANT_OPEN
	
	file.store_buffer(data)
	var checksum := fnv_hash_1a_32(data)
	file.store_64(checksum)
	file.close()
	return OK

static func safe_load_raw(filepath: String) -> PackedByteArray:
	var file1 : String = filepath + "1.bin"
	var file2 : String = filepath + "2.bin"
	
	var data1: PackedByteArray = read_entire_file_with_checksum(file1)
	if data1 != null and (not data1.is_empty()):
		return data1
	
	var data2: PackedByteArray = read_entire_file_with_checksum(file2)
	# if error if will return an empty one
	return data2
	
	
static func safe_save_raw(data: PackedByteArray, filepath: String) -> Error:
	var file1 : String = filepath + "1.bin"
	var file2 : String = filepath + "2.bin"
	
	var err1 : Error = write_entire_file_with_checksum(file1, data)
	if err1 != OK:
		push_warning("Failed to write to " + file1)
		return OK
	
	var err2 : Error = write_entire_file_with_checksum(file2, data)
	return err2
	


static func safe_load(filepath: String) -> Variant:
	var raw_data := safe_load_raw(filepath)
	if raw_data.is_empty():
		return null
	var data = bytes_to_var(raw_data)
	# check for error... not really needed cause of checksum but still
	# if typeof(data) == TYPE_INT:
	#	if data == ERR_INVALID_DATA:
	#		return null
	return data

static func safe_save(data: Variant, filepath: String) -> Error:
	var raw_data := var_to_bytes(data)
	return safe_save_raw(raw_data, filepath)

static func fnv_hash_1a_32(data: PackedByteArray) -> int:
	var h : int = 0x811c9dc5
	var len : int = data.size()

	if len >= 4:
		for i in range(0, len - 3, 4):
			h ^= data[i]        # h = (h ^ p[i + 0])
			h *= 0x01000193
			h ^= data[i + 1]    # h = (h ^ p[i + 1])
			h *= 0x01000193
			h ^= data[i + 2]    # h = (h ^ p[i + 2])
			h *= 0x01000193
			h ^= data[i + 3]    # h = (h ^ p[i + 3])
			h *= 0x01000193

	for i in range(len - (len % 4), len):
		h ^= data[i]        # h = (h ^ p[i])
		h *= 0x01000193

	return h
	
func _enter_tree():
	pass

func _exit_tree():
	pass
