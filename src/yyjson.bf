/*==============================================================================
 Copyright (c) 2020 YaoYuan <ibireme@gmail.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 *============================================================================*/

/**
 @file yyjson.h
 @date 2019-03-09
 @author YaoYuan
 */

using System;
using System.Interop;

namespace yyjson;

public static class yyjson
{
	/*==============================================================================
	* Version
	*============================================================================*/

	/** The major version of yyjson. */
	const c_int YYJSON_VERSION_MAJOR  = 0;

	/** The minor version of yyjson. */
	const c_int YYJSON_VERSION_MINOR  = 10;

	/** The patch version of yyjson. */
	const c_int YYJSON_VERSION_PATCH  = 0;

	/** The version of yyjson in hex: `(major << 16) | (minor << 8) | (patch)`. */
	const c_int YYJSON_VERSION_HEX    = 0x000A00;

	/** The version string of yyjson. */
	const String YYJSON_VERSION_STRING = "0.10.0";

	/** The version of yyjson in hex, same as `YYJSON_VERSION_HEX`. */
	[CLink] public static extern uint32_t yyjson_version();

	/*==============================================================================
	* JSON Types
	*============================================================================*/

	typealias char = c_char;
	typealias size_t = uint;
	typealias uint8_t = uint8;
	typealias uint32_t = uint32;
	typealias uint64_t = uint64;
	typealias int8_t = int8;
	typealias int16_t = int16;
	typealias int32_t = int32;
	typealias int64_t = int64;

	/** Type of a JSON value (3 bit). */
	typealias yyjson_type = uint8_t;
	/** No type, invalid. */
	const uint8_t YYJSON_TYPE_NONE        = 0; /* _____000 */
	/** Raw string type, no subtype. */
	const uint8_t YYJSON_TYPE_RAW         = 1; /* _____001 */
	/** Null type: `null` literal, no subtype. */
	const uint8_t YYJSON_TYPE_NULL        = 2; /* _____010 */
	/** Boolean type, subtype: TRUE, FALSE. */
	const uint8_t YYJSON_TYPE_BOOL        = 3; /* _____011 */
	/** Number type, subtype: UINT, SINT, REAL. */
	const uint8_t YYJSON_TYPE_NUM         = 4; /* _____100 */
	/** String type, subtype: NONE, NOESC. */
	const uint8_t YYJSON_TYPE_STR         = 5; /* _____101 */
	/** Array type, no subtype. */
	const uint8_t YYJSON_TYPE_ARR         = 6; /* _____110 */
	/** Object type, no subtype. */
	const uint8_t YYJSON_TYPE_OBJ         = 7; /* _____111 */

	/** Subtype of a JSON value (2 bit). */
	typealias yyjson_subtype = uint8_t;
	/** No subtype. */
	const uint8_t YYJSON_SUBTYPE_NONE     = 0 << 3; /* ___00___ */
	/** False subtype: `false` literal. */
	const uint8_t YYJSON_SUBTYPE_FALSE    = 0 << 3; /* ___00___ */
	/** True subtype: `true` literal. */
	const uint8_t YYJSON_SUBTYPE_TRUE     = 1 << 3; /* ___01___ */
	/** Unsigned integer subtype: `uint64_t`. */
	const uint8_t YYJSON_SUBTYPE_UINT     = 0 << 3; /* ___00___ */
	/** Signed integer subtype: `int64_t`. */
	const uint8_t YYJSON_SUBTYPE_SINT     = 1 << 3; /* ___01___ */
	/** Real number subtype: `double`. */
	const uint8_t YYJSON_SUBTYPE_REAL     = 2 << 3; /* ___10___ */
	/** String that do not need to be escaped for writing (internal use). */
	const uint8_t YYJSON_SUBTYPE_NOESC    = 1 << 3; /* ___01___ */

	/** The mask used to extract the type of a JSON value. */
	const uint8_t YYJSON_TYPE_MASK        = 0x07; /* _____111 */
	/** The number of bits used by the type. */
	const uint8_t YYJSON_TYPE_BIT         = 3;
	/** The mask used to extract the subtype of a JSON value. */
	const uint8_t YYJSON_SUBTYPE_MASK     = 0x18; /* ___11___ */
	/** The number of bits used by the subtype. */
	const uint8_t YYJSON_SUBTYPE_BIT      = 2;
	/** The mask used to extract the reserved bits of a JSON value. */
	const uint8_t YYJSON_RESERVED_MASK    = 0xE0; /* 111_____ */
	/** The number of reserved bits. */
	const uint8_t YYJSON_RESERVED_BIT     = 3;
	/** The mask used to extract the tag of a JSON value. */
	const uint8_t YYJSON_TAG_MASK         = 0xFF; /* 11111111 */
	/** The number of bits used by the tag. */
	const uint8_t YYJSON_TAG_BIT          = 8;

	/** Padding size for JSON reader. */
	const c_int YYJSON_PADDING_SIZE       = 4;


	/*==============================================================================
	* Allocator
	*============================================================================*/

	/**
	A memory allocator.

	Typically you don't need to use it, unless you want to customize your own
	memory allocator.
	*/
	[CRepr]
	public struct yyjson_alc
	{
		/** Same as libc's malloc(size), should not be NULL. */
		function void*(void* ctx, size_t size) malloc;
		/** Same as libc's realloc(ptr, size), should not be NULL. */
		function void*(void* ctx, void* ptr, size_t old_size, size_t size) realloc;
		/** Same as libc's free(ptr), should not be NULL. */
		function void(void* ctx, void* ptr) free;
		/** A context for malloc/realloc/free, can be NULL. */
		void* ctx;
	}

	/**
	A pool allocator uses fixed length pre-allocated memory.

	This allocator may be used to avoid malloc/realloc calls. The pre-allocated
	memory should be held by the caller. The maximum amount of memory required to
	read a JSON can be calculated using the `yyjson_read_max_memory_usage()`
	function, but the amount of memory required to write a JSON cannot be directly
	calculated.

	This is not a general-purpose allocator. It is designed to handle a single JSON
	data at a time. If it is used for overly complex memory tasks, such as parsing
	multiple JSON documents using the same allocator but releasing only a few of
	them, it may cause memory fragmentation, resulting in performance degradation
	and memory waste.

	@param alc The allocator to be initialized.
		If this parameter is NULL, the function will fail and return false.
		If `buf` or `size` is invalid, this will be set to an empty allocator.
	@param buf The buffer memory for this allocator.
		If this parameter is NULL, the function will fail and return false.
	@param size The size of `buf`, in bytes.
		If this parameter is less than 8 words (32/64 bytes on 32/64-bit OS), the
		function will fail and return false.
	@return true if the `alc` has been successfully initialized.

	@par Example
	@code
		// parse JSON with stack memory
		char buf[1024];
		yyjson_alc alc;
		yyjson_alc_pool_init(&alc, buf, 1024);

		char *json = "{\"name\":\"Helvetica\",\"size\":16}"
		yyjson_doc *doc = yyjson_read_opts(json, strlen(json), 0, &alc, NULL);
		// the memory of `doc` is on the stack
	@endcode

	@warning This Allocator is not thread-safe.
	*/
	[CLink] public static extern bool yyjson_alc_pool_init(yyjson_alc* alc, void* buf, size_t size);

	/**
	A dynamic allocator.

	This allocator has a similar usage to the pool allocator above. However, when
	there is not enough memory, this allocator will dynamically request more memory
	using libc's `malloc` function, and frees it all at once when it is destroyed.

	@return A new dynamic allocator, or NULL if memory allocation failed.
	@note The returned value should be freed with `yyjson_alc_dyn_free()`.

	@warning This Allocator is not thread-safe.
	*/
	[CLink] public static extern yyjson_alc* yyjson_alc_dyn_new();

	/**
	Free a dynamic allocator which is created by `yyjson_alc_dyn_new()`.
	@param alc The dynamic allocator to be destroyed.
	*/
	[CLink] public static extern void yyjson_alc_dyn_free(yyjson_alc* alc);

	/*==============================================================================
	* Text Locating
	*============================================================================*/

	/**
	Locate the line and column number for a byte position in a string.
	This can be used to get better description for error position.

	@param str The input string.
	@param len The byte length of the input string.
	@param pos The byte position within the input string.
	@param line A pointer to receive the line number, starting from 1.
	@param col  A pointer to receive the column number, starting from 1.
	@param chr  A pointer to receive the character index, starting from 0.
	@return true on success, false if `str` is NULL or `pos` is out of bounds.
	@note Line/column/character are calculated based on Unicode characters for
		compatibility with text editors. For multi-byte UTF-8 characters,
		the returned value may not directly correspond to the byte position.
	*/
	[CLink] public static extern bool yyjson_locate_pos(char* str, size_t len, size_t pos, size_t* line, size_t* col, size_t* chr);

	/*==============================================================================
	* JSON Structure
	*============================================================================*/

	/**
	 An immutable document for reading JSON.
	 This document holds memory for all its JSON values and strings. When it is no
	 longer used, the user should call `yyjson_doc_free()` to free its memory.
	 */
	/*[CRepr]
	public struct yyjson_doc;*/

	/**
	 An immutable value for reading JSON.
	 A JSON Value has the same lifetime as its document. The memory is held by its
	 document and and cannot be freed alone.
	 */
	/*[CRepr]
	public struct yyjson_val;*/

	/**
	 A mutable document for building JSON.
	 This document holds memory for all its JSON values and strings. When it is no
	 longer used, the user should call `yyjson_mut_doc_free()` to free its memory.
	 */
	/*[CRepr]
	public struct yyjson_mut_doc;*/

	/**
	 A mutable value for building JSON.
	 A JSON Value has the same lifetime as its document. The memory is held by its
	 document and and cannot be freed alone.
	 */
	/*[CRepr]
	public struct yyjson_mut_val;*/

	/*==============================================================================
	 * JSON Reader API
	 *============================================================================*/

	/** Run-time options for JSON reader. */
	typealias yyjson_read_flag = uint32_t;

	/** Default option (RFC 8259 compliant):
		- Read positive integer as uint64_t.
		- Read negative integer as int64_t.
		- Read floating-point number as double with round-to-nearest mode.
		- Read integer which cannot fit in uint64_t or int64_t as double.
		- Report error if double number is infinity.
		- Report error if string contains invalid UTF-8 character or BOM.
		- Report error on trailing commas, comments, inf and nan literals. */
	const yyjson_read_flag YYJSON_READ_NOFLAG                = 0;

	/** Read the input data in-situ.
		This option allows the reader to modify and use input data to store string
		values, which can increase reading speed slightly.
		The caller should hold the input data before free the document.
		The input data must be padded by at least `YYJSON_PADDING_SIZE` bytes.
		For example: `[1,2]` should be `[1,2]\0\0\0\0`, input length should be 5. */
	const yyjson_read_flag YYJSON_READ_INSITU                = 1 << 0;

	/** Stop when done instead of issuing an error if there's additional content
		after a JSON document. This option may be used to parse small pieces of JSON
		in larger data, such as `NDJSON`. */
	const yyjson_read_flag YYJSON_READ_STOP_WHEN_DONE        = 1 << 1;

	/** Allow single trailing comma at the end of an object or array,
		such as `[1,2,3,]`, `{"a":1,"b":2,}` (non-standard). */
	const yyjson_read_flag YYJSON_READ_ALLOW_TRAILING_COMMAS = 1 << 2;

	/** Allow C-style single line and multiple line comments (non-standard). */
	const yyjson_read_flag YYJSON_READ_ALLOW_COMMENTS        = 1 << 3;

	/** Allow inf/nan number and literal, case-insensitive,
		such as 1e999, NaN, inf, -Infinity (non-standard). */
	const yyjson_read_flag YYJSON_READ_ALLOW_INF_AND_NAN     = 1 << 4;

	/** Read all numbers as raw strings (value with `YYJSON_TYPE_RAW` type),
		inf/nan literal is also read as raw with `ALLOW_INF_AND_NAN` flag. */
	const yyjson_read_flag YYJSON_READ_NUMBER_AS_RAW         = 1 << 5;

	/** Allow reading invalid unicode when parsing string values (non-standard).
		Invalid characters will be allowed to appear in the string values, but
		invalid escape sequences will still be reported as errors.
		This flag does not affect the performance of correctly encoded strings.

		@warning Strings in JSON values may contain incorrect encoding when this
		option is used, you need to handle these strings carefully to avoid security
		risks. */
	const yyjson_read_flag YYJSON_READ_ALLOW_INVALID_UNICODE = 1 << 6;

	/** Read big numbers as raw strings. These big numbers include integers that
		cannot be represented by `int64_t` and `uint64_t`, and floating-point
		numbers that cannot be represented by finite `double`.
		The flag will be overridden by `YYJSON_READ_NUMBER_AS_RAW` flag. */
	const yyjson_read_flag YYJSON_READ_BIGNUM_AS_RAW         = 1 << 7;



	/** Result code for JSON reader. */
	typealias yyjson_read_code = uint32_t;

	/** Success, no error. */
	const yyjson_read_code YYJSON_READ_SUCCESS                       = 0;

	/** Invalid parameter, such as NULL input string or 0 input length. */
	const yyjson_read_code YYJSON_READ_ERROR_INVALID_PARAMETER       = 1;

	/** Memory allocation failure occurs. */
	const yyjson_read_code YYJSON_READ_ERROR_MEMORY_ALLOCATION       = 2;

	/** Input JSON string is empty. */
	const yyjson_read_code YYJSON_READ_ERROR_EMPTY_CONTENT           = 3;

	/** Unexpected content after document, such as `[123]abc`. */
	const yyjson_read_code YYJSON_READ_ERROR_UNEXPECTED_CONTENT      = 4;

	/** Unexpected ending, such as `[123`. */
	const yyjson_read_code YYJSON_READ_ERROR_UNEXPECTED_END          = 5;

	/** Unexpected character inside the document, such as `[abc]`. */
	const yyjson_read_code YYJSON_READ_ERROR_UNEXPECTED_CHARACTER    = 6;

	/** Invalid JSON structure, such as `[1,]`. */
	const yyjson_read_code YYJSON_READ_ERROR_JSON_STRUCTURE          = 7;

	/** Invalid comment, such as unclosed multi-line comment. */
	const yyjson_read_code YYJSON_READ_ERROR_INVALID_COMMENT         = 8;

	/** Invalid number, such as `123.e12`, `000`. */
	const yyjson_read_code YYJSON_READ_ERROR_INVALID_NUMBER          = 9;

	/** Invalid string, such as invalid escaped character inside a string. */
	const yyjson_read_code YYJSON_READ_ERROR_INVALID_STRING          = 10;

	/** Invalid JSON literal, such as `truu`. */
	const yyjson_read_code YYJSON_READ_ERROR_LITERAL                 = 11;

	/** Failed to open a file. */
	const yyjson_read_code YYJSON_READ_ERROR_FILE_OPEN               = 12;

	/** Failed to read a file. */
	const yyjson_read_code YYJSON_READ_ERROR_FILE_READ               = 13;

	/** Error information for JSON reader. */
	[CRepr]
	public struct yyjson_read_err
	{
		/** Error code, see `yyjson_read_code` for all possible values. */
		yyjson_read_code code;
		/** Error message, constant, no need to free (NULL if success). */
		char* msg;
		/** Error byte position for input data (0 if success). */
		size_t pos;
	}

	#if !(YYJSON_DISABLE_READER) || !YYJSON_DISABLE_READER

	/**
	Read JSON with options.

	This function is thread-safe when:
	1. The `dat` is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param dat The JSON data (UTF-8 without BOM), null-terminator is not required.
		If this parameter is NULL, the function will fail and return NULL.
		The `dat` will not be modified without the flag `YYJSON_READ_INSITU`, so you
		can pass a `char *` string and case it to `char *` if you don't use
		the `YYJSON_READ_INSITU` flag.
	@param len The length of JSON data in bytes.
		If this parameter is 0, the function will fail and return NULL.
	@param flg The JSON read options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON reader.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return A new JSON document, or NULL if an error occurs.
		When it's no longer needed, it should be freed with `yyjson_doc_free()`.
	*/
	[CLink] public static extern yyjson_doc* yyjson_read_opts(char* dat, size_t len, yyjson_read_flag flg, yyjson_alc* alc, yyjson_read_err* err);

	/**
	Read a JSON file.

	This function is thread-safe when:
	1. The file is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
		If this path is NULL or invalid, the function will fail and return NULL.
	@param flg The JSON read options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON reader.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return A new JSON document, or NULL if an error occurs.
		When it's no longer needed, it should be freed with `yyjson_doc_free()`.

	@warning On 32-bit operating system, files larger than 2GB may fail to read.
	*/
	[CLink] public static extern yyjson_doc* yyjson_read_file(char* path, yyjson_read_flag flg, yyjson_alc* alc, yyjson_read_err* err);

	/**
	Read JSON from a file pointer.

	@param fp The file pointer.
		The data will be read from the current position of the FILE to the end.
		If this fp is NULL or invalid, the function will fail and return NULL.
	@param flg The JSON read options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON reader.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return A new JSON document, or NULL if an error occurs.
		When it's no longer needed, it should be freed with `yyjson_doc_free()`.

	@warning On 32-bit operating system, files larger than 2GB may fail to read.
	*/
	// [CLink] public static extern yyjson_doc *yyjson_read_fp(FILE *fp, yyjson_read_flag flg, yyjson_alc *alc, yyjson_read_err *err);


	/**
	 Read a JSON string.

	 This function is thread-safe.

	 @param dat The JSON data (UTF-8 without BOM), null-terminator is not required.
		If this parameter is NULL, the function will fail and return NULL.
	 @param len The length of JSON data in bytes.
		If this parameter is 0, the function will fail and return NULL.
	 @param flg The JSON read options.
		Multiple options can be combined with `|` operator. 0 means no options.
	 @return A new JSON document, or NULL if an error occurs.
		When it's no longer needed, it should be freed with `yyjson_doc_free()`.
	 */
	public static yyjson_doc* yyjson_read(char* dat, size_t len, yyjson_read_flag flg)
	{
		return yyjson_read_opts(dat, len, flg, null, null);
	}

	/**
	Read a JSON number.

	This function is thread-safe when data is not modified by other threads.

	@param dat The JSON data (UTF-8 without BOM), null-terminator is required.
		If this parameter is NULL, the function will fail and return NULL.
	@param val The output value where result is stored.
		If this parameter is NULL, the function will fail and return NULL.
		The value will hold either UINT or SINT or REAL number;
	@param flg The JSON read options.
		Multiple options can be combined with `|` operator. 0 means no options.
		Supports `YYJSON_READ_NUMBER_AS_RAW` and `YYJSON_READ_ALLOW_INF_AND_NAN`.
	@param alc The memory allocator used for long number.
		It is only used when the built-in floating point reader is disabled.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return If successful, a pointer to the character after the last character
		used in the conversion, NULL if an error occurs.
	*/
	[CLink] public static extern char* yyjson_read_number(char* dat, yyjson_val* val, yyjson_read_flag flg, yyjson_alc* alc, yyjson_read_err* err);

#endif /* YYJSON_DISABLE_READER) */ 

	/*==============================================================================
	* JSON Writer API
	*============================================================================*/

	/** Run-time options for JSON writer. */
	typealias yyjson_write_flag = uint32_t;

	/** Default option:
		- Write JSON minify.
		- Report error on inf or nan number.
		- Report error on invalid UTF-8 string.
		- Do not escape unicode or slash. */
	const yyjson_write_flag YYJSON_WRITE_NOFLAG                  = 0;

	/** Write JSON pretty with 4 space indent. */
	const yyjson_write_flag YYJSON_WRITE_PRETTY                  = 1 << 0;

	/** Escape unicode as `uXXXX`, make the output ASCII only. */
	const yyjson_write_flag YYJSON_WRITE_ESCAPE_UNICODE          = 1 << 1;

	/** Escape '/' as '\/'. */
	const yyjson_write_flag YYJSON_WRITE_ESCAPE_SLASHES          = 1 << 2;

	/** Write inf and nan number as 'Infinity' and 'NaN' literal (non-standard). */
	const yyjson_write_flag YYJSON_WRITE_ALLOW_INF_AND_NAN       = 1 << 3;

	/** Write inf and nan number as null literal.
		This flag will override `YYJSON_WRITE_ALLOW_INF_AND_NAN` flag. */
	const yyjson_write_flag YYJSON_WRITE_INF_AND_NAN_AS_NULL     = 1 << 4;

	/** Allow invalid unicode when encoding string values (non-standard).
		Invalid characters in string value will be copied byte by byte.
		If `YYJSON_WRITE_ESCAPE_UNICODE` flag is also set, invalid character will be
		escaped as `U+FFFD` (replacement character).
		This flag does not affect the performance of correctly encoded strings. */
	const yyjson_write_flag YYJSON_WRITE_ALLOW_INVALID_UNICODE   = 1 << 5;

	/** Write JSON pretty with 2 space indent.
		This flag will override `YYJSON_WRITE_PRETTY` flag. */
	const yyjson_write_flag YYJSON_WRITE_PRETTY_TWO_SPACES       = 1 << 6;

	/** Adds a newline character `\n` at the end of the JSON.
		This can be helpful for text editors or NDJSON. */
	const yyjson_write_flag YYJSON_WRITE_NEWLINE_AT_END          = 1 << 7;



	/** The highest 8 bits of `yyjson_write_flag` and real number value's `tag`
		are reserved for controlling the output format of floating-point numbers. */
	const c_int YYJSON_WRITE_FP_FLAG_BITS = 8;

	/** The highest 4 bits of flag are reserved for precision value. */
	const c_int YYJSON_WRITE_FP_PREC_BITS = 4;

	/** Write floating-point number using fixed-point notation.
		- This is similar to ECMAScript `Number.prototype.toFixed(prec)`,
		but with trailing zeros removed. The `prec` ranges from 1 to 15.
		- This will produce shorter output but may lose some precision. */
	// #define YYJSON_WRITE_FP_TO_FIXED(prec) ((yyjson_write_flag)( \
	//     (uint32_t)((uint32_t)(prec)) << (32 - 4) ))

	/** Write floating-point numbers using single-precision (float).
		- This casts `double` to `float` before serialization.
		- This will produce shorter output, but may lose some precision.
		- This flag is ignored if `YYJSON_WRITE_FP_TO_FIXED(prec)` is also used. */
	// #define YYJSON_WRITE_FP_TO_FLOAT ((yyjson_write_flag)(1 << (32 - 5)))



	/** Result code for JSON writer */
	typealias yyjson_write_code = uint32_t;

	/** Success, no error. */
	const yyjson_write_code YYJSON_WRITE_SUCCESS                     = 0;

	/** Invalid parameter, such as NULL document. */
	const yyjson_write_code YYJSON_WRITE_ERROR_INVALID_PARAMETER     = 1;

	/** Memory allocation failure occurs. */
	const yyjson_write_code YYJSON_WRITE_ERROR_MEMORY_ALLOCATION     = 2;

	/** Invalid value type in JSON document. */
	const yyjson_write_code YYJSON_WRITE_ERROR_INVALID_VALUE_TYPE    = 3;

	/** NaN or Infinity number occurs. */
	const yyjson_write_code YYJSON_WRITE_ERROR_NAN_OR_INF            = 4;

	/** Failed to open a file. */
	const yyjson_write_code YYJSON_WRITE_ERROR_FILE_OPEN             = 5;

	/** Failed to write a file. */
	const yyjson_write_code YYJSON_WRITE_ERROR_FILE_WRITE            = 6;

	/** Invalid unicode in string. */
	const yyjson_write_code YYJSON_WRITE_ERROR_INVALID_STRING        = 7;

	/** Error information for JSON writer. */
	[CRepr]
	public struct yyjson_write_err {
		/** Error code, see `yyjson_write_code` for all possible values. */
		yyjson_write_code code;
		/** Error message, constant, no need to free (NULL if success). */
		char *msg;
	}

	#if !YYJSON_DISABLE_WRITER

	/*==============================================================================
	* JSON Document Writer API
	*============================================================================*/

	/**
	Write a document to JSON string with options.

	This function is thread-safe when:
	The `alc` is thread-safe or NULL.

	@param doc The JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free() or alc->free().
	*/
	[CLink] public static extern char *yyjson_write_opts(yyjson_doc *doc, yyjson_write_flag flg, yyjson_alc *alc, size_t *len, yyjson_write_err *err);

	/**
	Write a document to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
		If this path is NULL or invalid, the function will fail and return false.
		If this file is not empty, the content will be discarded.
	@param doc The JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	[CLink] public static extern bool yyjson_write_file(char *path, yyjson_doc *doc, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a document to file pointer with options.

	@param fp The file pointer.
		The data will be written to the current position of the file.
		If this fp is NULL or invalid, the function will fail and return false.
	@param doc The JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	//[CLink] public static extern bool yyjson_write_fp(FILE *fp, yyjson_doc *doc, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);


	/**
	Write a document to JSON string with options.

	This function is thread-safe when:
	1. The `doc` is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param doc The mutable JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free() or alc->free().
	*/
	[CLink] public static extern char *yyjson_mut_write_opts(yyjson_mut_doc *doc, yyjson_write_flag flg, yyjson_alc *alc, size_t *len, yyjson_write_err *err);

	/**
	Write a document to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `doc` is not modified by other threads.
	3. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
		If this path is NULL or invalid, the function will fail and return false.
		If this file is not empty, the content will be discarded.
	@param doc The mutable JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	[CLink] public static extern bool yyjson_mut_write_file(char *path, yyjson_mut_doc *doc, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a document to file pointer with options.

	@param fp The file pointer.
		The data will be written to the current position of the file.
		If this fp is NULL or invalid, the function will fail and return false.
	@param doc The mutable JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	//[CLink] public static extern bool yyjson_mut_write_fp(FILE *fp, yyjson_mut_doc *doc, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a document to JSON string.

	This function is thread-safe when:
	The `doc` is not modified by other threads.

	@param doc The JSON document.
		If this doc is NULL or has no root, the function will fail and return false.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free().
	*/
	// public static char *yyjson_mut_write(yyjson_mut_doc *doc, yyjson_write_flag flg,  size_t *len) {
	//     return yyjson_mut_write_opts(doc, flg, NULL, len, NULL);
	// }


	/*==============================================================================
	* JSON Value Writer API
	*============================================================================*/

	/**
	Write a value to JSON string with options.

	This function is thread-safe when:
	The `alc` is thread-safe or NULL.

	@param val The JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free() or alc->free().
	*/
	[CLink] public static extern char *yyjson_val_write_opts(yyjson_val *val, yyjson_write_flag flg, yyjson_alc *alc, size_t *len, yyjson_write_err *err);

	/**
	Write a value to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
		If this path is NULL or invalid, the function will fail and return false.
		If this file is not empty, the content will be discarded.
	@param val The JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	[CLink] public static extern bool yyjson_val_write_file(char *path, yyjson_val *val, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a value to file pointer with options.

	@param fp The file pointer.
		The data will be written to the current position of the file.
		If this path is NULL or invalid, the function will fail and return false.
	@param val The JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	//[CLink] public static extern bool yyjson_val_write_fp(FILE *fp, yyjson_val *val, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a value to JSON string.

	This function is thread-safe.

	@param val The JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free().
	*/
	// public static char *yyjson_val_write(yyjson_val *val, yyjson_write_flag flg, size_t *len) {
	//     return yyjson_val_write_opts(val, flg, NULL, len, NULL);
	// }

	/**
	Write a value to JSON string with options.

	This function is thread-safe when:
	1. The `val` is not modified by other threads.
	2. The `alc` is thread-safe or NULL.

	@param val The mutable JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return  A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free() or alc->free().
	*/
	[CLink] public static extern char *yyjson_mut_val_write_opts(yyjson_mut_val *val, yyjson_write_flag flg, yyjson_alc *alc, size_t *len, yyjson_write_err *err);

	/**
	Write a value to JSON file with options.

	This function is thread-safe when:
	1. The file is not accessed by other threads.
	2. The `val` is not modified by other threads.
	3. The `alc` is thread-safe or NULL.

	@param path The JSON file's path.
		If this path is NULL or invalid, the function will fail and return false.
		If this file is not empty, the content will be discarded.
	@param val The mutable JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	[CLink] public static extern bool yyjson_mut_val_write_file(char *path, yyjson_mut_val *val, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a value to JSON file with options.

	@param fp The file pointer.
		The data will be written to the current position of the file.
		If this path is NULL or invalid, the function will fail and return false.
	@param val The mutable JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param alc The memory allocator used by JSON writer.
		Pass NULL to use the libc's default allocator.
	@param err A pointer to receive error information.
		Pass NULL if you don't need error information.
	@return true if successful, false if an error occurs.

	@warning On 32-bit operating system, files larger than 2GB may fail to write.
	*/
	//[CLink] public static extern bool yyjson_mut_val_write_fp(FILE *fp, yyjson_mut_val *val, yyjson_write_flag flg, yyjson_alc *alc, yyjson_write_err *err);

	/**
	Write a value to JSON string.

	This function is thread-safe when:
	The `val` is not modified by other threads.

	@param val The JSON root value.
		If this parameter is NULL, the function will fail and return NULL.
	@param flg The JSON write options.
		Multiple options can be combined with `|` operator. 0 means no options.
	@param len A pointer to receive output length in bytes (not including the
		null-terminator). Pass NULL if you don't need length information.
	@return A new JSON string, or NULL if an error occurs.
		This string is encoded as UTF-8 with a null-terminator.
		When it's no longer needed, it should be freed with free().
	*/
	// [CLink] public static char *yyjson_mut_val_write(yyjson_mut_val *val,
	//                                              yyjson_write_flag flg,
	//                                              size_t *len) {
	//     return yyjson_mut_val_write_opts(val, flg, NULL, len, NULL);
	// }

	#endif /* YYJSON_DISABLE_WRITER */



	/*==============================================================================
	* JSON Document API
	*============================================================================*/

	/** Returns the root value of this JSON document.
		Returns NULL if `doc` is NULL. */
	[CLink] public static extern yyjson_val *yyjson_doc_get_root(yyjson_doc *doc);

	/** Returns read size of input JSON data.
		Returns 0 if `doc` is NULL.
		For example: the read size of `[1,2,3]` is 7 bytes.  */
	[CLink] public static extern size_t yyjson_doc_get_read_size(yyjson_doc *doc);

	/** Returns total value count in this JSON document.
		Returns 0 if `doc` is NULL.
		For example: the value count of `[1,2,3]` is 4. */
	[CLink] public static extern size_t yyjson_doc_get_val_count(yyjson_doc *doc);

	/** Release the JSON document and free the memory.
		After calling this function, the `doc` and all values from the `doc` are no
		longer available. This function will do nothing if the `doc` is NULL. */
	[CLink] public static extern void yyjson_doc_free(yyjson_doc *doc);



	/*==============================================================================
	* JSON Value Type API
	*============================================================================*/

	/** Returns whether the JSON value is raw.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_raw(yyjson_val *val);

	/** Returns whether the JSON value is `null`.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_null(yyjson_val *val);

	/** Returns whether the JSON value is `true`.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_true(yyjson_val *val);

	/** Returns whether the JSON value is `false`.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_false(yyjson_val *val);

	/** Returns whether the JSON value is bool (true/false).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_bool(yyjson_val *val);

	/** Returns whether the JSON value is unsigned integer (uint64_t).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_uint(yyjson_val *val);

	/** Returns whether the JSON value is signed integer (int64_t).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_sint(yyjson_val *val);

	/** Returns whether the JSON value is integer (uint64_t/int64_t).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_int(yyjson_val *val);

	/** Returns whether the JSON value is real number (double).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_real(yyjson_val *val);

	/** Returns whether the JSON value is number (uint64_t/int64_t/double).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_num(yyjson_val *val);

	/** Returns whether the JSON value is string.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_str(yyjson_val *val);

	/** Returns whether the JSON value is array.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_arr(yyjson_val *val);

	/** Returns whether the JSON value is object.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_obj(yyjson_val *val);

	/** Returns whether the JSON value is container (array/object).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_is_ctn(yyjson_val *val);



	/*==============================================================================
	* JSON Value Content API
	*============================================================================*/

	/** Returns the JSON value's type.
		Returns YYJSON_TYPE_NONE if `val` is NULL. */
	[CLink] public static extern yyjson_type yyjson_get_type(yyjson_val *val);

	/** Returns the JSON value's subtype.
		Returns YYJSON_SUBTYPE_NONE if `val` is NULL. */
	[CLink] public static extern yyjson_subtype yyjson_get_subtype(yyjson_val *val);

	/** Returns the JSON value's tag.
		Returns 0 if `val` is NULL. */
	[CLink] public static extern uint8_t yyjson_get_tag(yyjson_val *val);

	/** Returns the JSON value's type description.
		The return value should be one of these strings: "raw", "null", "string",
		"array", "object", "true", "false", "uint", "sint", "real", "unknown". */
	[CLink] public static extern char *yyjson_get_type_desc(yyjson_val *val);

	/** Returns the content if the value is raw.
		Returns NULL if `val` is NULL or type is not raw. */
	[CLink] public static extern char *yyjson_get_raw(yyjson_val *val);

	/** Returns the content if the value is bool.
		Returns NULL if `val` is NULL or type is not bool. */
	[CLink] public static extern bool yyjson_get_bool(yyjson_val *val);

	/** Returns the content and cast to uint64_t.
		Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	[CLink] public static extern uint64_t yyjson_get_uint(yyjson_val *val);

	/** Returns the content and cast to int64_t.
		Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	[CLink] public static extern int64_t yyjson_get_sint(yyjson_val *val);

	/** Returns the content and cast to c_int.
		Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	[CLink] public static extern c_int yyjson_get_int(yyjson_val *val);

	/** Returns the content if the value is real number, or 0.0 on error.
		Returns 0.0 if `val` is NULL or type is not real(double). */
	[CLink] public static extern double yyjson_get_real(yyjson_val *val);

	/** Returns the content and typecast to `double` if the value is number.
		Returns 0.0 if `val` is NULL or type is not number(uint/sint/real). */
	[CLink] public static extern double yyjson_get_num(yyjson_val *val);

	/** Returns the content if the value is string.
		Returns NULL if `val` is NULL or type is not string. */
	[CLink] public static extern char* yyjson_get_str(yyjson_val *val);

	/** Returns the content length (string length, array size, object size.
		Returns 0 if `val` is NULL or type is not string/array/object. */
	[CLink] public static extern size_t yyjson_get_len(yyjson_val *val);

	/** Returns whether the JSON value is equals to a string.
		Returns false if input is NULL or type is not string. */
	[CLink] public static extern bool yyjson_equals_str(yyjson_val *val, char *str);

	/** Returns whether the JSON value is equals to a string.
		The `str` should be a UTF-8 string, null-terminator is not required.
		Returns false if input is NULL or type is not string. */
	[CLink] public static extern bool yyjson_equals_strn(yyjson_val *val, char *str, size_t len);

	/** Returns whether two JSON values are equal (deep compare).
		Returns false if input is NULL.
		@note the result may be inaccurate if object has duplicate keys.
		@warning This function is recursive and may cause a stack overflow
			if the object level is too deep. */
	[CLink] public static extern bool yyjson_equals(yyjson_val *lhs, yyjson_val *rhs);

	/** Set the value to raw.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_raw(yyjson_val *val, char *raw, size_t len);

	/** Set the value to null.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_null(yyjson_val *val);

	/** Set the value to bool.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_bool(yyjson_val *val, bool num);

	/** Set the value to uint.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_uint(yyjson_val *val, uint64_t num);

	/** Set the value to sint.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_sint(yyjson_val *val, int64_t num);

	/** Set the value to c_int.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_int(yyjson_val *val, c_int num);

	/** Set the value to float.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_float(yyjson_val *val, float num);

	/** Set the value to double.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_double(yyjson_val *val, double num);

	/** Set the value to real.
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_real(yyjson_val *val, double num);

	/** Set the floating-point number's output format to fixed-point notation.
		Returns false if input is NULL or `val` is not real type.
		@see YYJSON_WRITE_FP_TO_FIXED flag.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_fp_to_fixed(yyjson_val *val, c_int prec);

	/** Set the floating-point number's output format to single-precision.
		Returns false if input is NULL or `val` is not real type.
		@see YYJSON_WRITE_FP_TO_FLOAT flag.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_fp_to_float(yyjson_val *val, bool flt);

	/** Set the value to string (null-terminated).
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_str(yyjson_val *val, char *str);

	/** Set the value to string (with length).
		Returns false if input is NULL or `val` is object or array.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_strn(yyjson_val *val, char *str, size_t len);

	/** Marks this string as not needing to be escaped during JSON writing.
		This can be used to avoid the overhead of escaping if the string contains
		only characters that do not require escaping.
		Returns false if input is NULL or `val` is not string.
		@see YYJSON_SUBTYPE_NOESC subtype.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_set_str_noesc(yyjson_val *val, bool noesc);



	/*==============================================================================
	* JSON Array API
	*============================================================================*/

	/** Returns the number of elements in this array.
		Returns 0 if `arr` is NULL or type is not array. */
	[CLink] public static extern size_t yyjson_arr_size(yyjson_val *arr);

	/** Returns the element at the specified position in this array.
		Returns NULL if array is NULL/empty or the index is out of bounds.
		@warning This function takes a linear search time if array is not flat.
			For example: `[1,{},3]` is flat, `[1,[2],3]` is not flat. */
	[CLink] public static extern yyjson_val *yyjson_arr_get(yyjson_val *arr, size_t idx);

	/** Returns the first element of this array.
		Returns NULL if `arr` is NULL/empty or type is not array. */
	[CLink] public static extern yyjson_val *yyjson_arr_get_first(yyjson_val *arr);

	/** Returns the last element of this array.
		Returns NULL if `arr` is NULL/empty or type is not array.
		@warning This function takes a linear search time if array is not flat.
			For example: `[1,{},3]` is flat, `[1,[2],3]` is not flat.*/
	[CLink] public static extern yyjson_val *yyjson_arr_get_last(yyjson_val *arr);



	/*==============================================================================
	* JSON Array Iterator API
	*============================================================================*/

	/**
	A JSON array iterator.

	@par Example
	@code
		yyjson_val *val;
		yyjson_arr_iter iter = yyjson_arr_iter_with(arr);
		while ((val = yyjson_arr_iter_next(&iter))) {
			your_func(val);
		}
	@endcode
	*/
	[CRepr]
	public struct yyjson_arr_iter {
		size_t idx; /**< next value's index */
		size_t max; /**< maximum index (arr.size) */
		yyjson_val *cur; /**< next value */
	}

	/**
	Initialize an iterator for this array.

	@param arr The array to be iterated over.
		If this parameter is NULL or not an array, `iter` will be set to empty.
	@param iter The iterator to be initialized.
		If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern bool yyjson_arr_iter_init(yyjson_val *arr, yyjson_arr_iter *iter);

	/**
	Create an iterator with an array , same as `yyjson_arr_iter_init()`.

	@param arr The array to be iterated over.
		If this parameter is NULL or not an array, an empty iterator will returned.
	@return A new iterator for the array.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern yyjson_arr_iter yyjson_arr_iter_with(yyjson_val *arr);

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	[CLink] public static extern bool yyjson_arr_iter_has_next(yyjson_arr_iter *iter);

	/**
	Returns the next element in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_val *yyjson_arr_iter_next(yyjson_arr_iter *iter);

	/**
	Macro for iterating over an array.
	It works like iterator, but with a more intuitive API.

	@par Example
	@code
		size_t idx, max;
		yyjson_val *val;
		yyjson_arr_foreach(arr, idx, max, val) {
			your_func(idx, val);
		}
	@endcode
	*/
	//#define yyjson_arr_foreach(arr, idx, max, val) \
	//	for ((idx) = 0, \
	//		(max) = yyjson_arr_size(arr), \
	//		(val) = yyjson_arr_get_first(arr); \
	//		(idx) < (max); \
	//		(idx)++, \
	//		(val) = unsafe_yyjson_get_next(val))



	/*==============================================================================
	* JSON Object API
	*============================================================================*/

	/** Returns the number of key-value pairs in this object.
		Returns 0 if `obj` is NULL or type is not object. */
	[CLink] public static extern size_t yyjson_obj_size(yyjson_val *obj);

	/** Returns the value to which the specified key is mapped.
		Returns NULL if this object contains no mapping for the key.
		Returns NULL if `obj/key` is NULL, or type is not object.

		The `key` should be a null-terminated UTF-8 string.

		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_val *yyjson_obj_get(yyjson_val *obj, char *key);

	/** Returns the value to which the specified key is mapped.
		Returns NULL if this object contains no mapping for the key.
		Returns NULL if `obj/key` is NULL, or type is not object.

		The `key` should be a UTF-8 string, null-terminator is not required.
		The `key_len` should be the length of the key, in bytes.

		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_val *yyjson_obj_getn(yyjson_val *obj, char *key, size_t key_len);


	/*==============================================================================
	* JSON Object Iterator API
	*============================================================================*/

	/**
	A JSON object iterator.

	@par Example
	@code
		yyjson_val *key, *val;
		yyjson_obj_iter iter = yyjson_obj_iter_with(obj);
		while ((key = yyjson_obj_iter_next(&iter))) {
			val = yyjson_obj_iter_get_val(key);
			your_func(key, val);
		}
	@endcode

	If the ordering of the keys is known at compile-time, you can use this method
	to speed up value lookups:
	@code
		// {"k1":1, "k2": 3, "k3": 3}
		yyjson_val *key, *val;
		yyjson_obj_iter iter = yyjson_obj_iter_with(obj);
		yyjson_val *v1 = yyjson_obj_iter_get(&iter, "k1");
		yyjson_val *v3 = yyjson_obj_iter_get(&iter, "k3");
	@endcode
	@see yyjson_obj_iter_get() and yyjson_obj_iter_getn()
	*/
	[CRepr]
	public struct yyjson_obj_iter {
		size_t idx; /**< next key's index */
		size_t max; /**< maximum key index (obj.size) */
		yyjson_val *cur; /**< next key */
		yyjson_val *obj; /**< the object being iterated */
	}

	/**
	Initialize an iterator for this object.

	@param obj The object to be iterated over.
		If this parameter is NULL or not an object, `iter` will be set to empty.
	@param iter The iterator to be initialized.
		If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern bool yyjson_obj_iter_init(yyjson_val *obj, yyjson_obj_iter *iter);

	/**
	Create an iterator with an object, same as `yyjson_obj_iter_init()`.

	@param obj The object to be iterated over.
		If this parameter is NULL or not an object, an empty iterator will returned.
	@return A new iterator for the object.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern yyjson_obj_iter yyjson_obj_iter_with(yyjson_val *obj);

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	[CLink] public static extern bool yyjson_obj_iter_has_next(yyjson_obj_iter *iter);

	/**
	Returns the next key in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_val *yyjson_obj_iter_next(yyjson_obj_iter *iter);

	/**
	Returns the value for key inside the iteration.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_val *yyjson_obj_iter_get_val(yyjson_val *key);

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_obj_get()`, but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string with null-terminator.
	@return The value to which the specified key is mapped.
		NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	[CLink] public static extern yyjson_val *yyjson_obj_iter_get(yyjson_obj_iter *iter, char *key);

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_obj_getn()`, but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string, null-terminator is not required.
	@param key_len The the length of `key`, in bytes.
	@return The value to which the specified key is mapped.
		NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	[CLink] public static extern yyjson_val *yyjson_obj_iter_getn(yyjson_obj_iter *iter, char *key, size_t key_len);

	/**
	Macro for iterating over an object.
	It works like iterator, but with a more intuitive API.

	@par Example
	@code
		size_t idx, max;
		yyjson_val *key, *val;
		yyjson_obj_foreach(obj, idx, max, key, val) {
			your_func(key, val);
		}
	@endcode
	*/
	//#define yyjson_obj_foreach(obj, idx, max, key, val) \
	//	for ((idx) = 0, \
	//		(max) = yyjson_obj_size(obj), \
	//		(key) = (obj) ? unsafe_yyjson_get_first(obj) : NULL, \
	//		(val) = (key) + 1; \
	//		(idx) < (max); \
	//		(idx)++, \
	//		(key) = unsafe_yyjson_get_next(val), \
	//		(val) = (key) + 1)

	/*==============================================================================
	* Mutable JSON Document API
	*============================================================================*/

	/** Returns the root value of this JSON document.
		Returns NULL if `doc` is NULL. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_get_root(yyjson_mut_doc *doc);

	/** Sets the root value of this JSON document.
		Pass NULL to clear root value of the document. */
	[CLink] public static extern void yyjson_mut_doc_set_root(yyjson_mut_doc *doc, yyjson_mut_val *root);

	/**
	Set the string pool size for a mutable document.
	This function does not allocate memory immediately, but uses the size when
	the next memory allocation is needed.

	If the caller knows the approximate bytes of strings that the document needs to
	store (e.g. copy string with `yyjson_mut_strcpy` function), setting a larger
	size can avoid multiple memory allocations and improve performance.

	@param doc The mutable document.
	@param len The desired string pool size in bytes (total string length).
	@return true if successful, false if size is 0 or overflow.
	*/
	[CLink] public static extern bool yyjson_mut_doc_set_str_pool_size(yyjson_mut_doc *doc, size_t len);

	/**
	Set the value pool size for a mutable document.
	This function does not allocate memory immediately, but uses the size when
	the next memory allocation is needed.

	If the caller knows the approximate number of values that the document needs to
	store (e.g. create new value with `yyjson_mut_xxx` functions), setting a larger
	size can avoid multiple memory allocations and improve performance.

	@param doc The mutable document.
	@param count The desired value pool size (number of `yyjson_mut_val`).
	@return true if successful, false if size is 0 or overflow.
	*/
	[CLink] public static extern bool yyjson_mut_doc_set_val_pool_size(yyjson_mut_doc *doc, size_t count);

	/** Release the JSON document and free the memory.
		After calling this function, the `doc` and all values from the `doc` are no
		longer available. This function will do nothing if the `doc` is NULL.  */
	[CLink] public static extern void yyjson_mut_doc_free(yyjson_mut_doc *doc);

	/** Creates and returns a new mutable JSON document, returns NULL on error.
		If allocator is NULL, the default allocator will be used. */
	[CLink] public static extern yyjson_mut_doc *yyjson_mut_doc_new(yyjson_alc *alc);

	/** Copies and returns a new mutable document from input, returns NULL on error.
		This makes a `deep-copy` on the immutable document.
		If allocator is NULL, the default allocator will be used.
		@note `imut_doc` -> `mut_doc`. */
	[CLink] public static extern yyjson_mut_doc *yyjson_doc_mut_copy(yyjson_doc *doc, yyjson_alc *alc);

	/** Copies and returns a new mutable document from input, returns NULL on error.
		This makes a `deep-copy` on the mutable document.
		If allocator is NULL, the default allocator will be used.
		@note `mut_doc` -> `mut_doc`. */
	[CLink] public static extern yyjson_mut_doc *yyjson_mut_doc_mut_copy(yyjson_mut_doc *doc, yyjson_alc *alc);

	/** Copies and returns a new mutable value from input, returns NULL on error.
		This makes a `deep-copy` on the immutable value.
		The memory was managed by mutable document.
		@note `imut_val` -> `mut_val`. */
	[CLink] public static extern yyjson_mut_val *yyjson_val_mut_copy(yyjson_mut_doc *doc, yyjson_val *val);

	/** Copies and returns a new mutable value from input, returns NULL on error.
		This makes a `deep-copy` on the mutable value.
		The memory was managed by mutable document.
		@note `mut_val` -> `mut_val`.
		@warning This function is recursive and may cause a stack overflow
			if the object level is too deep. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_val_mut_copy(yyjson_mut_doc *doc, yyjson_mut_val *val);

	/** Copies and returns a new immutable document from input,
		returns NULL on error. This makes a `deep-copy` on the mutable document.
		The returned document should be freed with `yyjson_doc_free()`.
		@note `mut_doc` -> `imut_doc`.
		@warning This function is recursive and may cause a stack overflow
			if the object level is too deep. */
	[CLink] public static extern yyjson_doc *yyjson_mut_doc_imut_copy(yyjson_mut_doc *doc, yyjson_alc *alc);

	/** Copies and returns a new immutable document from input,
		returns NULL on error. This makes a `deep-copy` on the mutable value.
		The returned document should be freed with `yyjson_doc_free()`.
		@note `mut_val` -> `imut_doc`.
		@warning This function is recursive and may cause a stack overflow
			if the object level is too deep. */
	[CLink] public static extern yyjson_doc *yyjson_mut_val_imut_copy(yyjson_mut_val *val, yyjson_alc *alc);


	/*==============================================================================
	* Mutable JSON Value Type API
	*============================================================================*/

	/** Returns whether the JSON value is raw.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_raw(yyjson_mut_val *val);

	/** Returns whether the JSON value is `null`.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_null(yyjson_mut_val *val);

	/** Returns whether the JSON value is `true`.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_true(yyjson_mut_val *val);

	/** Returns whether the JSON value is `false`.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_false(yyjson_mut_val *val);

	/** Returns whether the JSON value is bool (true/false).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_bool(yyjson_mut_val *val);

	/** Returns whether the JSON value is unsigned integer (uint64_t).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_uint(yyjson_mut_val *val);

	/** Returns whether the JSON value is signed integer (int64_t).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_sint(yyjson_mut_val *val);

	/** Returns whether the JSON value is integer (uint64_t/int64_t).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_int(yyjson_mut_val *val);

	/** Returns whether the JSON value is real number (double).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_real(yyjson_mut_val *val);

	/** Returns whether the JSON value is number (uint/sint/real).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_num(yyjson_mut_val *val);

	/** Returns whether the JSON value is string.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_str(yyjson_mut_val *val);

	/** Returns whether the JSON value is array.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_arr(yyjson_mut_val *val);

	/** Returns whether the JSON value is object.
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_obj(yyjson_mut_val *val);

	/** Returns whether the JSON value is container (array/object).
		Returns false if `val` is NULL. */
	[CLink] public static extern bool yyjson_mut_is_ctn(yyjson_mut_val *val);



	/*==============================================================================
	* Mutable JSON Value Content API
	*============================================================================*/

	/** Returns the JSON value's type.
		Returns `YYJSON_TYPE_NONE` if `val` is NULL. */
	[CLink] public static extern yyjson_type yyjson_mut_get_type(yyjson_mut_val *val);

	/** Returns the JSON value's subtype.
		Returns `YYJSON_SUBTYPE_NONE` if `val` is NULL. */
	[CLink] public static extern yyjson_subtype yyjson_mut_get_subtype(yyjson_mut_val *val);

	/** Returns the JSON value's tag.
		Returns 0 if `val` is NULL. */
	[CLink] public static extern uint8_t yyjson_mut_get_tag(yyjson_mut_val *val);

	/** Returns the JSON value's type description.
		The return value should be one of these strings: "raw", "null", "string",
		"array", "object", "true", "false", "uint", "sint", "real", "unknown". */
	[CLink] public static extern char *yyjson_mut_get_type_desc(yyjson_mut_val *val);

	/** Returns the content if the value is raw.
		Returns NULL if `val` is NULL or type is not raw. */
	[CLink] public static extern char *yyjson_mut_get_raw(yyjson_mut_val *val);

	/** Returns the content if the value is bool.
		Returns NULL if `val` is NULL or type is not bool. */
	[CLink] public static extern bool yyjson_mut_get_bool(yyjson_mut_val *val);

	/** Returns the content and cast to uint64_t.
		Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	[CLink] public static extern uint64_t yyjson_mut_get_uint(yyjson_mut_val *val);

	/** Returns the content and cast to int64_t.
		Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	[CLink] public static extern int64_t yyjson_mut_get_sint(yyjson_mut_val *val);

	/** Returns the content and cast to c_int.
		Returns 0 if `val` is NULL or type is not integer(sint/uint). */
	[CLink] public static extern c_int yyjson_mut_get_int(yyjson_mut_val *val);

	/** Returns the content if the value is real number.
		Returns 0.0 if `val` is NULL or type is not real(double). */
	[CLink] public static extern double yyjson_mut_get_real(yyjson_mut_val *val);

	/** Returns the content and typecast to `double` if the value is number.
		Returns 0.0 if `val` is NULL or type is not number(uint/sint/real). */
	[CLink] public static extern double yyjson_mut_get_num(yyjson_mut_val *val);

	/** Returns the content if the value is string.
		Returns NULL if `val` is NULL or type is not string. */
	[CLink] public static extern char *yyjson_mut_get_str(yyjson_mut_val *val);

	/** Returns the content length (string length, array size, object size.
		Returns 0 if `val` is NULL or type is not string/array/object. */
	[CLink] public static extern size_t yyjson_mut_get_len(yyjson_mut_val *val);

	/** Returns whether the JSON value is equals to a string.
		The `str` should be a null-terminated UTF-8 string.
		Returns false if input is NULL or type is not string. */
	[CLink] public static extern bool yyjson_mut_equals_str(yyjson_mut_val *val, char *str);

	/** Returns whether the JSON value is equals to a string.
		The `str` should be a UTF-8 string, null-terminator is not required.
		Returns false if input is NULL or type is not string. */
	[CLink] public static extern bool yyjson_mut_equals_strn(yyjson_mut_val *val, char *str, size_t len);

	/** Returns whether two JSON values are equal (deep compare).
		Returns false if input is NULL.
		@note the result may be inaccurate if object has duplicate keys.
		@warning This function is recursive and may cause a stack overflow
			if the object level is too deep. */
	[CLink] public static extern bool yyjson_mut_equals(yyjson_mut_val *lhs, yyjson_mut_val *rhs);

	/** Set the value to raw.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_raw(yyjson_mut_val *val, char *raw, size_t len);

	/** Set the value to null.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_null(yyjson_mut_val *val);

	/** Set the value to bool.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_bool(yyjson_mut_val *val, bool num);

	/** Set the value to uint.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_uint(yyjson_mut_val *val, uint64_t num);

	/** Set the value to sint.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_sint(yyjson_mut_val *val, int64_t num);

	/** Set the value to c_int.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_int(yyjson_mut_val *val, c_int num);

	/** Set the value to float.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_float(yyjson_mut_val *val, float num);

	/** Set the value to double.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_double(yyjson_mut_val *val, double num);

	/** Set the value to real.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_real(yyjson_mut_val *val, double num);

	/** Set the floating-point number's output format to fixed-point notation.
		Returns false if input is NULL or `val` is not real type.
		@see YYJSON_WRITE_FP_TO_FIXED flag.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_mut_set_fp_to_fixed(yyjson_mut_val *val, c_int prec);

	/** Set the floating-point number's output format to single-precision.
		Returns false if input is NULL or `val` is not real type.
		@see YYJSON_WRITE_FP_TO_FLOAT flag.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_mut_set_fp_to_float(yyjson_mut_val *val, bool flt);

	/** Set the value to string (null-terminated).
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_str(yyjson_mut_val *val, char *str);

	/** Set the value to string (with length).
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_strn(yyjson_mut_val *val, char *str, size_t len);

	/** Marks this string as not needing to be escaped during JSON writing.
		This can be used to avoid the overhead of escaping if the string contains
		only characters that do not require escaping.
		Returns false if input is NULL or `val` is not string.
		@see YYJSON_SUBTYPE_NOESC subtype.
		@warning This will modify the `immutable` value, use with caution. */
	[CLink] public static extern bool yyjson_mut_set_str_noesc(yyjson_mut_val *val, bool noesc);

	/** Set the value to array.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_arr(yyjson_mut_val *val);

	/** Set the value to array.
		Returns false if input is NULL.
		@warning This function should not be used on an existing object or array. */
	[CLink] public static extern bool yyjson_mut_set_obj(yyjson_mut_val *val);

	/*==============================================================================
	* Mutable JSON Value Creation API
	*============================================================================*/

	/** Creates and returns a raw value, returns NULL on error.
		The `str` should be a null-terminated UTF-8 string.

		@warning The input string is not copied, you should keep this string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_raw(yyjson_mut_doc *doc, char *str);

	/** Creates and returns a raw value, returns NULL on error.
		The `str` should be a UTF-8 string, null-terminator is not required.

		@warning The input string is not copied, you should keep this string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_rawn(yyjson_mut_doc *doc, char *str, size_t len);

	/** Creates and returns a raw value, returns NULL on error.
		The `str` should be a null-terminated UTF-8 string.
		The input string is copied and held by the document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_rawcpy(yyjson_mut_doc *doc, char *str);

	/** Creates and returns a raw value, returns NULL on error.
		The `str` should be a UTF-8 string, null-terminator is not required.
		The input string is copied and held by the document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_rawncpy(yyjson_mut_doc *doc, char *str, size_t len);

	/** Creates and returns a null value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_null(yyjson_mut_doc *doc);

	/** Creates and returns a true value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_true(yyjson_mut_doc *doc);

	/** Creates and returns a false value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_false(yyjson_mut_doc *doc);

	/** Creates and returns a bool value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_bool(yyjson_mut_doc *doc, bool val);

	/** Creates and returns an unsigned integer value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_uint(yyjson_mut_doc *doc, uint64_t num);

	/** Creates and returns a signed integer value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_sint(yyjson_mut_doc *doc, int64_t num);

	/** Creates and returns a signed integer value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_int(yyjson_mut_doc *doc, int64_t num);

	/** Creates and returns a float number value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_float(yyjson_mut_doc *doc, float num);

	/** Creates and returns a double number value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_double(yyjson_mut_doc *doc, double num);

	/** Creates and returns a real number value, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_real(yyjson_mut_doc *doc, double num);

	/** Creates and returns a string value, returns NULL on error.
		The `str` should be a null-terminated UTF-8 string.
		@warning The input string is not copied, you should keep this string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_str(yyjson_mut_doc *doc, char *str);

	/** Creates and returns a string value, returns NULL on error.
		The `str` should be a UTF-8 string, null-terminator is not required.
		@warning The input string is not copied, you should keep this string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_strn(yyjson_mut_doc *doc, char *str, size_t len);

	/** Creates and returns a string value, returns NULL on error.
		The `str` should be a null-terminated UTF-8 string.
		The input string is copied and held by the document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_strcpy(yyjson_mut_doc *doc, char *str);

	/** Creates and returns a string value, returns NULL on error.
		The `str` should be a UTF-8 string, null-terminator is not required.
		The input string is copied and held by the document. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_strncpy(yyjson_mut_doc *doc, char *str, size_t len);



	/*==============================================================================
	* Mutable JSON Array API
	*============================================================================*/

	/** Returns the number of elements in this array.
		Returns 0 if `arr` is NULL or type is not array. */
	[CLink] public static extern size_t yyjson_mut_arr_size(yyjson_mut_val *arr);

	/** Returns the element at the specified position in this array.
		Returns NULL if array is NULL/empty or the index is out of bounds.
		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_get(yyjson_mut_val *arr, size_t idx);

	/** Returns the first element of this array.
		Returns NULL if `arr` is NULL/empty or type is not array. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_get_first(yyjson_mut_val *arr);

	/** Returns the last element of this array.
		Returns NULL if `arr` is NULL/empty or type is not array. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_get_last(yyjson_mut_val *arr);

	/*==============================================================================
	* Mutable JSON Array Iterator API
	*============================================================================*/

	/**
	A mutable JSON array iterator.

	@warning You should not modify the array while iterating over it, but you can
		use `yyjson_mut_arr_iter_remove()` to remove current value.

	@par Example
	@code
		yyjson_mut_val *val;
		yyjson_mut_arr_iter iter = yyjson_mut_arr_iter_with(arr);
		while ((val = yyjson_mut_arr_iter_next(&iter))) {
			your_func(val);
			if (your_val_is_unused(val)) {
				yyjson_mut_arr_iter_remove(&iter);
			}
		}
	@endcode
	*/
	[CRepr]
	public struct yyjson_mut_arr_iter {
		size_t idx; /**< next value's index */
		size_t max; /**< maximum index (arr.size) */
		yyjson_mut_val *cur; /**< current value */
		yyjson_mut_val *pre; /**< previous value */
		yyjson_mut_val *arr; /**< the array being iterated */
	}

	/**
	Initialize an iterator for this array.

	@param arr The array to be iterated over.
		If this parameter is NULL or not an array, `iter` will be set to empty.
	@param iter The iterator to be initialized.
		If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern bool yyjson_mut_arr_iter_init(yyjson_mut_val *arr, yyjson_mut_arr_iter *iter);

	/**
	Create an iterator with an array , same as `yyjson_mut_arr_iter_init()`.

	@param arr The array to be iterated over.
		If this parameter is NULL or not an array, an empty iterator will returned.
	@return A new iterator for the array.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern yyjson_mut_arr_iter yyjson_mut_arr_iter_with(yyjson_mut_val *arr);

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	[CLink] public static extern bool yyjson_mut_arr_iter_has_next(yyjson_mut_arr_iter *iter);

	/**
	Returns the next element in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_iter_next(yyjson_mut_arr_iter *iter);

	/**
	Removes and returns current element in the iteration.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_iter_remove(yyjson_mut_arr_iter *iter);

	/**
	Macro for iterating over an array.
	It works like iterator, but with a more intuitive API.

	@warning You should not modify the array while iterating over it.

	@par Example
	@code
		size_t idx, max;
		yyjson_mut_val *val;
		yyjson_mut_arr_foreach(arr, idx, max, val) {
			your_func(idx, val);
		}
	@endcode
	*/
	/*#define yyjson_mut_arr_foreach(arr, idx, max, val) \
		for ((idx) = 0, \
			(max) = yyjson_mut_arr_size(arr), \
			(val) = yyjson_mut_arr_get_first(arr); \
			(idx) < (max); \
			(idx)++, \
			(val) = (val)->next)*/



	/*==============================================================================
	* Mutable JSON Array Creation API
	*============================================================================*/

	/**
	Creates and returns an empty mutable array.
	@param doc A mutable document, used for memory allocation only.
	@return The new array. NULL if input is NULL or memory allocation failed.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr(yyjson_mut_doc *doc);

	/**
	Creates and returns a new mutable array with the given boolean values.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of boolean values.
	@param count The value count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const bool vals[3] = { true, false, true };
		yyjson_mut_val *arr = yyjson_mut_arr_with_bool(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_bool(yyjson_mut_doc *doc, bool *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given sint numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of sint numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const int64_t vals[3] = { -1, 0, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_sint64(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_sint(yyjson_mut_doc *doc, int64_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given uint numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const uint64_t vals[3] = { 0, 1, 0 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_uint(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_uint(yyjson_mut_doc *doc, uint64_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given real numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of real numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const double vals[3] = { 0.1, 0.2, 0.3 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_real(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_real(yyjson_mut_doc *doc, double *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given int8 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int8 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const int8_t vals[3] = { -1, 0, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_sint8(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_sint8(yyjson_mut_doc *doc, int8_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given int16 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int16 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const int16_t vals[3] = { -1, 0, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_sint16(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_sint16(yyjson_mut_doc *doc, int16_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given int32 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int32 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const int32_t vals[3] = { -1, 0, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_sint32(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_sint32(yyjson_mut_doc *doc, int32_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given int64 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of int64 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const int64_t vals[3] = { -1, 0, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_sint64(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_sint64(yyjson_mut_doc *doc, int64_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given uint8 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint8 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const uint8_t vals[3] = { 0, 1, 0 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_uint8(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_uint8(yyjson_mut_doc *doc, uint8_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given uint16 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint16 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const uint16_t vals[3] = { 0, 1, 0 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_uint16(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_uint16(yyjson_mut_doc *doc, int16_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given uint32 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint32 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const uint32_t vals[3] = { 0, 1, 0 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_uint32(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_uint32(yyjson_mut_doc *doc, uint32_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given uint64 numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of uint64 numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const uint64_t vals[3] = { 0, 1, 0 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_uint64(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_uint64(yyjson_mut_doc *doc, uint64_t *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given float numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of float numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const float vals[3] = { -1.0f, 0.0f, 1.0f };
		yyjson_mut_val *arr = yyjson_mut_arr_with_float(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_float(yyjson_mut_doc *doc, float *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given double numbers.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of double numbers.
	@param count The number count. If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		const double vals[3] = { -1.0, 0.0, 1.0 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_double(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_double(yyjson_mut_doc *doc, double *vals, size_t count);

	/**
	Creates and returns a new mutable array with the given strings, these strings
	will not be copied.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 null-terminator strings.
		If this array contains NULL, the function will fail and return NULL.
	@param count The number of values in `vals`.
		If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@warning The input strings are not copied, you should keep these strings
		unmodified for the lifetime of this JSON document. If these strings will be
		modified, you should use `yyjson_mut_arr_with_strcpy()` instead.

	@par Example
	@code
		char *vals[3] = { "a", "b", "c" };
		yyjson_mut_val *arr = yyjson_mut_arr_with_str(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_str(yyjson_mut_doc *doc, char **vals, size_t count);

	/**
	Creates and returns a new mutable array with the given strings and string
	lengths, these strings will not be copied.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 strings, null-terminator is not required.
		If this array contains NULL, the function will fail and return NULL.
	@param lens A C array of string lengths, in bytes.
	@param count The number of strings in `vals`.
		If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@warning The input strings are not copied, you should keep these strings
		unmodified for the lifetime of this JSON document. If these strings will be
		modified, you should use `yyjson_mut_arr_with_strncpy()` instead.

	@par Example
	@code
		char *vals[3] = { "a", "bb", "c" };
		const size_t lens[3] = { 1, 2, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_strn(doc, vals, lens, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_strn(yyjson_mut_doc *doc, char **vals, size_t *lens, size_t count);

	/**
	Creates and returns a new mutable array with the given strings, these strings
	will be copied.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 null-terminator strings.
		If this array contains NULL, the function will fail and return NULL.
	@param count The number of values in `vals`.
		If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		char *vals[3] = { "a", "b", "c" };
		yyjson_mut_val *arr = yyjson_mut_arr_with_strcpy(doc, vals, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_strcpy(yyjson_mut_doc *doc, char **vals, size_t count);

	/**
	Creates and returns a new mutable array with the given strings and string
	lengths, these strings will be copied.

	@param doc A mutable document, used for memory allocation only.
		If this parameter is NULL, the function will fail and return NULL.
	@param vals A C array of UTF-8 strings, null-terminator is not required.
		If this array contains NULL, the function will fail and return NULL.
	@param lens A C array of string lengths, in bytes.
	@param count The number of strings in `vals`.
		If this value is 0, an empty array will return.
	@return The new array. NULL if input is invalid or memory allocation failed.

	@par Example
	@code
		char *vals[3] = { "a", "bb", "c" };
		const size_t lens[3] = { 1, 2, 1 };
		yyjson_mut_val *arr = yyjson_mut_arr_with_strn(doc, vals, lens, 3);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_with_strncpy(yyjson_mut_doc *doc, char **vals, size_t *lens, size_t count);



	/*==============================================================================
	* Mutable JSON Array Modification API
	*============================================================================*/

	/**
	Inserts a value into an array at a given index.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@param idx The index to which to insert the new value.
		Returns false if the index is out of range.
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern bool yyjson_mut_arr_insert(yyjson_mut_val *arr, yyjson_mut_val *val, size_t idx);

	/**
	Inserts a value at the end of the array.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_append(yyjson_mut_val *arr, yyjson_mut_val *val);

	/**
	Inserts a value at the head of the array.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@return    Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_prepend(yyjson_mut_val *arr, yyjson_mut_val *val);

	/**
	Replaces a value at index and returns old value.
	@param arr The array to which the value is to be replaced.
		Returns false if it is NULL or not an array.
	@param idx The index to which to replace the value.
		Returns false if the index is out of range.
	@param val The new value to replace. Returns false if it is NULL.
	@return Old value, or NULL on error.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_replace(yyjson_mut_val *arr, size_t idx, yyjson_mut_val *val);

	/**
	Removes and returns a value at index.
	@param arr The array from which the value is to be removed.
		Returns false if it is NULL or not an array.
	@param idx The index from which to remove the value.
		Returns false if the index is out of range.
	@return Old value, or NULL on error.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_remove(yyjson_mut_val *arr, size_t idx);

	/**
	Removes and returns the first value in this array.
	@param arr The array from which the value is to be removed.
		Returns false if it is NULL or not an array.
	@return The first value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_remove_first(yyjson_mut_val *arr);

	/**
	Removes and returns the last value in this array.
	@param arr The array from which the value is to be removed.
		Returns false if it is NULL or not an array.
	@return The last value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_remove_last(yyjson_mut_val *arr);

	/**
	Removes all values within a specified range in the array.
	@param arr The array from which the value is to be removed.
		Returns false if it is NULL or not an array.
	@param idx The start index of the range (0 is the first).
	@param len The number of items in the range (can be 0).
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern bool yyjson_mut_arr_remove_range(yyjson_mut_val *arr, size_t idx, size_t len);

	/**
	Removes all values in this array.
	@param arr The array from which all of the values are to be removed.
		Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_clear(yyjson_mut_val *arr);

	/**
	Rotates values in this array for the given number of times.
	For example: `[1,2,3,4,5]` rotate 2 is `[3,4,5,1,2]`.
	@param arr The array to be rotated.
	@param idx Index (or times) to rotate.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern bool yyjson_mut_arr_rotate(yyjson_mut_val *arr, size_t idx);



	/*==============================================================================
	* Mutable JSON Array Modification Convenience API
	*============================================================================*/

	/**
	Adds a value at the end of the array.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param val The value to be inserted. Returns false if it is NULL.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_val(yyjson_mut_val *arr, yyjson_mut_val *val);

	/**
	Adds a `null` value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_null(yyjson_mut_doc *doc, yyjson_mut_val *arr);

	/**
	Adds a `true` value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_true(yyjson_mut_doc *doc, yyjson_mut_val *arr);

	/**
	Adds a `false` value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_false(yyjson_mut_doc *doc, yyjson_mut_val *arr);

	/**
	Adds a bool value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param val The bool value to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_bool(yyjson_mut_doc *doc, yyjson_mut_val *arr, bool val);

	/**
	Adds an unsigned integer value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_uint(yyjson_mut_doc *doc, yyjson_mut_val *arr, uint64_t num);

	/**
	Adds a signed integer value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_sint(yyjson_mut_doc *doc, yyjson_mut_val *arr, int64_t num);

	/**
	Adds an integer value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_int(yyjson_mut_doc *doc, yyjson_mut_val *arr, int64_t num);

	/**
	Adds a float value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_float(yyjson_mut_doc *doc, yyjson_mut_val *arr, float num);

	/**
	Adds a double value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_double(yyjson_mut_doc *doc, yyjson_mut_val *arr, double num);

	/**
	Adds a double value at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param num The number to be added.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_real(yyjson_mut_doc *doc, yyjson_mut_val *arr, double num);

	/**
	Adds a string value at the end of the array (no copy).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param str A null-terminated UTF-8 string.
	@return Whether successful.
	@warning The input string is not copied, you should keep this string unmodified
		for the lifetime of this JSON document.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_str(yyjson_mut_doc *doc, yyjson_mut_val *arr, char *str);

	/**
	Adds a string value at the end of the array (no copy).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param str A UTF-8 string, null-terminator is not required.
	@param len The length of the string, in bytes.
	@return Whether successful.
	@warning The input string is not copied, you should keep this string unmodified
		for the lifetime of this JSON document.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_strn(yyjson_mut_doc *doc, yyjson_mut_val *arr, char *str, size_t len);

	/**
	Adds a string value at the end of the array (copied).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param str A null-terminated UTF-8 string.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_strcpy(yyjson_mut_doc *doc, yyjson_mut_val *arr, char *str);

	/**
	Adds a string value at the end of the array (copied).
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@param str A UTF-8 string, null-terminator is not required.
	@param len The length of the string, in bytes.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_arr_add_strncpy(yyjson_mut_doc *doc, yyjson_mut_val *arr, char *str, size_t len);

	/**
	Creates and adds a new array at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@return The new array, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_add_arr(yyjson_mut_doc *doc, yyjson_mut_val *arr);

	/**
	Creates and adds a new object at the end of the array.
	@param doc The `doc` is only used for memory allocation.
	@param arr The array to which the value is to be inserted.
		Returns false if it is NULL or not an array.
	@return The new object, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_arr_add_obj(yyjson_mut_doc *doc, yyjson_mut_val *arr);



	/*==============================================================================
	* Mutable JSON Object API
	*============================================================================*/

	/** Returns the number of key-value pairs in this object.
		Returns 0 if `obj` is NULL or type is not object. */
	[CLink] public static extern size_t yyjson_mut_obj_size(yyjson_mut_val *obj);

	/** Returns the value to which the specified key is mapped.
		Returns NULL if this object contains no mapping for the key.
		Returns NULL if `obj/key` is NULL, or type is not object.

		The `key` should be a null-terminated UTF-8 string.

		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_get(yyjson_mut_val *obj, char *key);

	/** Returns the value to which the specified key is mapped.
		Returns NULL if this object contains no mapping for the key.
		Returns NULL if `obj/key` is NULL, or type is not object.

		The `key` should be a UTF-8 string, null-terminator is not required.
		The `key_len` should be the length of the key, in bytes.

		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_getn(yyjson_mut_val *obj, char *key, size_t key_len);



	/*==============================================================================
	* Mutable JSON Object Iterator API
	*============================================================================*/

	/**
	A mutable JSON object iterator.

	@warning You should not modify the object while iterating over it, but you can
		use `yyjson_mut_obj_iter_remove()` to remove current value.

	@par Example
	@code
		yyjson_mut_val *key, *val;
		yyjson_mut_obj_iter iter = yyjson_mut_obj_iter_with(obj);
		while ((key = yyjson_mut_obj_iter_next(&iter))) {
			val = yyjson_mut_obj_iter_get_val(key);
			your_func(key, val);
			if (your_val_is_unused(key, val)) {
				yyjson_mut_obj_iter_remove(&iter);
			}
		}
	@endcode

	If the ordering of the keys is known at compile-time, you can use this method
	to speed up value lookups:
	@code
		// {"k1":1, "k2": 3, "k3": 3}
		yyjson_mut_val *key, *val;
		yyjson_mut_obj_iter iter = yyjson_mut_obj_iter_with(obj);
		yyjson_mut_val *v1 = yyjson_mut_obj_iter_get(&iter, "k1");
		yyjson_mut_val *v3 = yyjson_mut_obj_iter_get(&iter, "k3");
	@endcode
	@see `yyjson_mut_obj_iter_get()` and `yyjson_mut_obj_iter_getn()`
	*/
	[CRepr]
	public struct yyjson_mut_obj_iter {
		size_t idx; /**< next key's index */
		size_t max; /**< maximum key index (obj.size) */
		yyjson_mut_val *cur; /**< current key */
		yyjson_mut_val *pre; /**< previous key */
		yyjson_mut_val *obj; /**< the object being iterated */
	}

	/**
	Initialize an iterator for this object.

	@param obj The object to be iterated over.
		If this parameter is NULL or not an array, `iter` will be set to empty.
	@param iter The iterator to be initialized.
		If this parameter is NULL, the function will fail and return false.
	@return true if the `iter` has been successfully initialized.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern bool yyjson_mut_obj_iter_init(yyjson_mut_val *obj, yyjson_mut_obj_iter *iter);

	/**
	Create an iterator with an object, same as `yyjson_obj_iter_init()`.

	@param obj The object to be iterated over.
		If this parameter is NULL or not an object, an empty iterator will returned.
	@return A new iterator for the object.

	@note The iterator does not need to be destroyed.
	*/
	[CLink] public static extern yyjson_mut_obj_iter yyjson_mut_obj_iter_with(yyjson_mut_val *obj);

	/**
	Returns whether the iteration has more elements.
	If `iter` is NULL, this function will return false.
	*/
	[CLink] public static extern bool yyjson_mut_obj_iter_has_next(yyjson_mut_obj_iter *iter);

	/**
	Returns the next key in the iteration, or NULL on end.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_iter_next(yyjson_mut_obj_iter *iter);

	/**
	Returns the value for key inside the iteration.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_iter_get_val(yyjson_mut_val *key);

	/**
	Removes current key-value pair in the iteration, returns the removed value.
	If `iter` is NULL, this function will return NULL.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_iter_remove(yyjson_mut_obj_iter *iter);

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_mut_obj_get()`, but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string with null-terminator.
	@return The value to which the specified key is mapped.
		NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_iter_get(yyjson_mut_obj_iter *iter, char *key);

	/**
	Iterates to a specified key and returns the value.

	This function does the same thing as `yyjson_mut_obj_getn()` but is much faster
	if the ordering of the keys is known at compile-time and you are using the same
	order to look up the values. If the key exists in this object, then the
	iterator will stop at the next key, otherwise the iterator will not change and
	NULL is returned.

	@param iter The object iterator, should not be NULL.
	@param key The key, should be a UTF-8 string, null-terminator is not required.
	@param key_len The the length of `key`, in bytes.
	@return The value to which the specified key is mapped.
		NULL if this object contains no mapping for the key or input is invalid.

	@warning This function takes a linear search time if the key is not nearby.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_iter_getn(yyjson_mut_obj_iter *iter, char *key, size_t key_len);

	/**
	Macro for iterating over an object.
	It works like iterator, but with a more intuitive API.

	@warning You should not modify the object while iterating over it.

	@par Example
	@code
		size_t idx, max;
		yyjson_val *key, *val;
		yyjson_obj_foreach(obj, idx, max, key, val) {
			your_func(key, val);
		}
	@endcode
	*/
	// #define yyjson_mut_obj_foreach(obj, idx, max, key, val) \
	//     for ((idx) = 0, \
	//         (max) = yyjson_mut_obj_size(obj), \
	//         (key) = (max) ? ((yyjson_mut_val *)(obj)->uni.ptr)->next->next : NULL, \
	//         (val) = (key) ? (key)->next : NULL; \
	//         (idx) < (max); \
	//         (idx)++, \
	//         (key) = (val)->next, \
	//         (val) = (key)->next)

	/*==============================================================================
	* Mutable JSON Structure (Implementation)
	*============================================================================*/

	/**
	Mutable JSON value, 24 bytes.
	The 'tag' and 'uni' field is same as immutable value.
	The 'next' field links all elements inside the container to be a cycle.
	*/
	[CRepr] 
	public struct yyjson_mut_val {
		uint64_t tag; /**< type, subtype and length */
		yyjson_val_uni uni; /**< payload */
		yyjson_mut_val *next; /**< the next value in circular linked list */
	}

	/**
	A memory chunk in string memory pool.
	*/
	[CRepr] 
	public struct yyjson_str_chunk {
		// struct yyjson_str_chunk *next; /* next chunk linked list */
		yyjson_str_chunk *next; /* next chunk linked list */
		size_t chunk_size; /* chunk size in bytes */
		/* char str[]; flexible array member */
	}

	/**
	A memory pool to hold all strings in a mutable document.
	*/
	[CRepr] 
	public struct yyjson_str_pool {
		char *cur; /* cursor inside current chunk */
		char *end; /* the end of current chunk */
		size_t chunk_size; /* chunk size in bytes while creating new chunk */
		size_t chunk_size_max; /* maximum chunk size in bytes */
		yyjson_str_chunk *chunks; /* a linked list of chunks, nullable */
	}

	/**
	A memory chunk in value memory pool.
	`sizeof(yyjson_val_chunk)` should not larger than `sizeof(yyjson_mut_val)`.
	*/
	[CRepr] 
	public struct yyjson_val_chunk {
		// struct yyjson_val_chunk *next; /* next chunk linked list */
		yyjson_val_chunk *next; /* next chunk linked list */
		size_t chunk_size; /* chunk size in bytes */
		/* char pad[sizeof(yyjson_mut_val) - sizeof(yyjson_val_chunk)]; padding */
		/* yyjson_mut_val vals[]; flexible array member */
	}

	/**
	A memory pool to hold all values in a mutable document.
	*/
	[CRepr] 
	public struct yyjson_val_pool {
		yyjson_mut_val *cur; /* cursor inside current chunk */
		yyjson_mut_val *end; /* the end of current chunk */
		size_t chunk_size; /* chunk size in bytes while creating new chunk */
		size_t chunk_size_max; /* maximum chunk size in bytes */
		yyjson_val_chunk *chunks; /* a linked list of chunks, nullable */
	} 

	[CRepr] 
	public struct yyjson_mut_doc {
		yyjson_mut_val *root; /**< root value of the JSON document, nullable */
		yyjson_alc alc; /**< a valid allocator, nonnull */
		yyjson_str_pool str_pool; /**< string memory pool */
		yyjson_val_pool val_pool; /**< value memory pool */
	}

	/*==============================================================================
	* Mutable JSON Object Creation API
	*============================================================================*/

	/** Creates and returns a mutable object, returns NULL on error. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj(yyjson_mut_doc *doc);

	/**
	Creates and returns a mutable object with keys and values, returns NULL on
	error. The keys and values are not copied. The strings should be a
	null-terminated UTF-8 string.

	@warning The input string is not copied, you should keep this string
		unmodified for the lifetime of this JSON document.

	@par Example
	@code
		char *keys[2] = { "id", "name" };
		char *vals[2] = { "01", "Harry" };
		yyjson_mut_val *obj = yyjson_mut_obj_with_str(doc, keys, vals, 2);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_with_str(yyjson_mut_doc *doc, char **keys, char **vals, size_t count);

	/**
	Creates and returns a mutable object with key-value pairs and pair count,
	returns NULL on error. The keys and values are not copied. The strings should
	be a null-terminated UTF-8 string.

	@warning The input string is not copied, you should keep this string
		unmodified for the lifetime of this JSON document.

	@par Example
	@code
		char *kv_pairs[4] = { "id", "01", "name", "Harry" };
		yyjson_mut_val *obj = yyjson_mut_obj_with_kv(doc, kv_pairs, 2);
	@endcode
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_with_kv(yyjson_mut_doc *doc, char **kv_pairs, size_t pair_count);

	/*==============================================================================
	* Mutable JSON Object Modification API
	*============================================================================*/

	/**
	Adds a key-value pair at the end of the object.
	This function allows duplicated key in one object.
	@param obj The object to which the new key-value pair is to be added.
	@param key The key, should be a string which is created by `yyjson_mut_str()`,
		`yyjson_mut_strn()`, `yyjson_mut_strcpy()` or `yyjson_mut_strncpy()`.
	@param val The value to add to the object.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_obj_add(yyjson_mut_val *obj, yyjson_mut_val *key, yyjson_mut_val *val);
	/**
	Sets a key-value pair at the end of the object.
	This function may remove all key-value pairs for the given key before add.
	@param obj The object to which the new key-value pair is to be added.
	@param key The key, should be a string which is created by `yyjson_mut_str()`,
		`yyjson_mut_strn()`, `yyjson_mut_strcpy()` or `yyjson_mut_strncpy()`.
	@param val The value to add to the object. If this value is null, the behavior
		is same as `yyjson_mut_obj_remove()`.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_obj_put(yyjson_mut_val *obj, yyjson_mut_val *key, yyjson_mut_val *val);

	/**
	Inserts a key-value pair to the object at the given position.
	This function allows duplicated key in one object.
	@param obj The object to which the new key-value pair is to be added.
	@param key The key, should be a string which is created by `yyjson_mut_str()`,
		`yyjson_mut_strn()`, `yyjson_mut_strcpy()` or `yyjson_mut_strncpy()`.
	@param val The value to add to the object.
	@param idx The index to which to insert the new pair.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_obj_insert(yyjson_mut_val *obj, yyjson_mut_val *key, yyjson_mut_val *val, size_t idx);

	/**
	Removes all key-value pair from the object with given key.
	@param obj The object from which the key-value pair is to be removed.
	@param key The key, should be a string value.
	@return The first matched value, or NULL if no matched value.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_remove(yyjson_mut_val *obj, yyjson_mut_val *key);

	/**
	Removes all key-value pair from the object with given key.
	@param obj The object from which the key-value pair is to be removed.
	@param key The key, should be a UTF-8 string with null-terminator.
	@return The first matched value, or NULL if no matched value.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_remove_key( yyjson_mut_val *obj, char *key);

	/**
	Removes all key-value pair from the object with given key.
	@param obj The object from which the key-value pair is to be removed.
	@param key The key, should be a UTF-8 string, null-terminator is not required.
	@param key_len The length of the key.
	@return The first matched value, or NULL if no matched value.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_remove_keyn(yyjson_mut_val *obj, char *key, size_t key_len);

	/**
	Removes all key-value pairs in this object.
	@param obj The object from which all of the values are to be removed.
	@return Whether successful.
	*/
	[CLink] public static extern bool yyjson_mut_obj_clear(yyjson_mut_val *obj);

	/**
	Replaces value from the object with given key.
	If the key is not exist, or the value is NULL, it will fail.
	@param obj The object to which the value is to be replaced.
	@param key The key, should be a string value.
	@param val The value to replace into the object.
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern bool yyjson_mut_obj_replace(yyjson_mut_val *obj, yyjson_mut_val *key, yyjson_mut_val *val);

	/**
	Rotates key-value pairs in the object for the given number of times.
	For example: `{"a":1,"b":2,"c":3,"d":4}` rotate 1 is
	`{"b":2,"c":3,"d":4,"a":1}`.
	@param obj The object to be rotated.
	@param idx Index (or times) to rotate.
	@return Whether successful.
	@warning This function takes a linear search time.
	*/
	[CLink] public static extern bool yyjson_mut_obj_rotate(yyjson_mut_val *obj, size_t idx);



	/*==============================================================================
	* Mutable JSON Object Modification Convenience API
	*============================================================================*/

	/** Adds a `null` value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_null(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key);

	/** Adds a `true` value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_true(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key);

	/** Adds a `false` value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_false(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key);

	/** Adds a bool value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_bool(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, bool val);

	/** Adds an unsigned integer value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_uint(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, uint64_t val);

	/** Adds a signed integer value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_sint(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, int64_t val);

	/** Adds an c_int value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_int(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, int64_t val);

	/** Adds a float value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_float(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, float val);

	/** Adds a double value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_double(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, double val);

	/** Adds a real value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_real(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, double val);

	/** Adds a string value at the end of the object.
		The `key` and `val` should be null-terminated UTF-8 strings.
		This function allows duplicated key in one object.

		@warning The key/value strings are not copied, you should keep these strings
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_str(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, char *val);

	/** Adds a string value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		The `val` should be a UTF-8 string, null-terminator is not required.
		The `len` should be the length of the `val`, in bytes.
		This function allows duplicated key in one object.

		@warning The key/value strings are not copied, you should keep these strings
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_strn(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, char *val, size_t len);

	/** Adds a string value at the end of the object.
		The `key` and `val` should be null-terminated UTF-8 strings.
		The value string is copied.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_strcpy(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, char *val);

	/** Adds a string value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		The `val` should be a UTF-8 string, null-terminator is not required.
		The `len` should be the length of the `val`, in bytes.
		This function allows duplicated key in one object.

		@warning The key strings are not copied, you should keep these strings
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_strncpy(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, char *val, size_t len);

	/**
	Creates and adds a new array to the target object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep these strings
			unmodified for the lifetime of this JSON document.
	@return The new array, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_add_arr(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key);

	/**
	Creates and adds a new object to the target object.
	The `key` should be a null-terminated UTF-8 string.
	This function allows duplicated key in one object.

	@warning The key string is not copied, you should keep these strings
			unmodified for the lifetime of this JSON document.
	@return The new object, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_add_obj(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key);

	/** Adds a JSON value at the end of the object.
		The `key` should be a null-terminated UTF-8 string.
		This function allows duplicated key in one object.

		@warning The key string is not copied, you should keep the string
			unmodified for the lifetime of this JSON document. */
	[CLink] public static extern bool yyjson_mut_obj_add_val(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, yyjson_mut_val *val);

	/** Removes all key-value pairs for the given key.
		Returns the first value to which the specified key is mapped or NULL if this
		object contains no mapping for the key.
		The `key` should be a null-terminated UTF-8 string.

		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_remove_str(yyjson_mut_val *obj, char *key);

	/** Removes all key-value pairs for the given key.
		Returns the first value to which the specified key is mapped or NULL if this
		object contains no mapping for the key.
		The `key` should be a UTF-8 string, null-terminator is not required.
		The `len` should be the length of the key, in bytes.

		@warning This function takes a linear search time. */
	[CLink] public static extern yyjson_mut_val *yyjson_mut_obj_remove_strn(yyjson_mut_val *obj, char *key, size_t len);

	/** Replaces all matching keys with the new key.
		Returns true if at least one key was renamed.
		The `key` and `new_key` should be a null-terminated UTF-8 string.
		The `new_key` is copied and held by doc.

		@warning This function takes a linear search time.
		If `new_key` already exists, it will cause duplicate keys.
	*/
	[CLink] public static extern bool yyjson_mut_obj_rename_key(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, char *new_key);

	/** Replaces all matching keys with the new key.
		Returns true if at least one key was renamed.
		The `key` and `new_key` should be a UTF-8 string,
		null-terminator is not required. The `new_key` is copied and held by doc.

		@warning This function takes a linear search time.
		If `new_key` already exists, it will cause duplicate keys.
	*/
	[CLink] public static extern bool yyjson_mut_obj_rename_keyn(yyjson_mut_doc *doc, yyjson_mut_val *obj, char *key, size_t len, char *new_key, size_t new_len);


#if !YYJSON_DISABLE_UTILS

	/*==============================================================================
	* JSON Pointer API (RFC 6901)
	* https://tools.ietf.org/html/rfc6901
	*============================================================================*/

	/** JSON Pointer error code. */
	typealias yyjson_ptr_code = uint32_t;

	/** No JSON pointer error. */
	const yyjson_ptr_code YYJSON_PTR_ERR_NONE = 0;

	/** Invalid input parameter, such as NULL input. */
	const yyjson_ptr_code YYJSON_PTR_ERR_PARAMETER = 1;

	/** JSON pointer syntax error, such as invalid escape, token no prefix. */
	const yyjson_ptr_code YYJSON_PTR_ERR_SYNTAX = 2;

	/** JSON pointer resolve failed, such as index out of range, key not found. */
	const yyjson_ptr_code YYJSON_PTR_ERR_RESOLVE = 3;

	/** Document's root is NULL, but it is required for the function call. */
	const yyjson_ptr_code YYJSON_PTR_ERR_NULL_ROOT = 4;

	/** Cannot set root as the target is not a document. */
	const yyjson_ptr_code YYJSON_PTR_ERR_SET_ROOT = 5;

	/** The memory allocation failed and a new value could not be created. */
	const yyjson_ptr_code YYJSON_PTR_ERR_MEMORY_ALLOCATION = 6;

	/** Error information for JSON pointer. */
	[CRepr]
	public struct yyjson_ptr_err {
		/** Error code, see `yyjson_ptr_code` for all possible values. */
		yyjson_ptr_code code;
		/** Error message, constant, no need to free (NULL if no error). */
		char *msg;
		/** Error byte position for input JSON pointer (0 if no error). */
		size_t pos;
	}

	/**
	A context for JSON pointer operation.

	This struct stores the context of JSON Pointer operation result. The struct
	can be used with three helper functions: `ctx_append()`, `ctx_replace()`, and
	`ctx_remove()`, which perform the corresponding operations on the container
	without re-parsing the JSON Pointer.

	For example:
	@code
		// doc before: {"a":[0,1,null]}
		// ptr: "/a/2"
		val = yyjson_mut_doc_ptr_getx(doc, ptr, strlen(ptr), &ctx, &err);
		if (yyjson_is_null(val)) {
			yyjson_ptr_ctx_remove(&ctx);
		}
		// doc after: {"a":[0,1]}
	@endcode
	*/
	[CRepr]
	public struct yyjson_ptr_ctx {
		/**
		The container (parent) of the target value. It can be either an array or
		an object. If the target location has no value, but all its parent
		containers exist, and the target location can be used to insert a new
		value, then `ctn` is the parent container of the target location.
		Otherwise, `ctn` is NULL.
		*/
		yyjson_mut_val *ctn;
		/**
		The previous sibling of the target value. It can be either a value in an
		array or a key in an object. As the container is a `circular linked list`
		of elements, `pre` is the previous node of the target value. If the
		operation is `add` or `set`, then `pre` is the previous node of the new
		value, not the original target value. If the target value does not exist,
		`pre` is NULL.
		*/
		yyjson_mut_val *pre;
		/**
		The removed value if the operation is `set`, `replace` or `remove`. It can
		be used to restore the original state of the document if needed.
		*/
		yyjson_mut_val *old;
	}

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
		NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_val *yyjson_doc_ptr_get(yyjson_doc *doc, char *ptr);

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
		NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_val *yyjson_doc_ptr_getn(yyjson_doc *doc, char *ptr, size_t len);

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
		NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_val *yyjson_doc_ptr_getx(yyjson_doc *doc, char *ptr, size_t len, yyjson_ptr_err *err);

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
		NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_val *yyjson_ptr_get(yyjson_val *val, char *ptr);

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
		NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_val *yyjson_ptr_getn(yyjson_val *val, char *ptr, size_t len);

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
		NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_val *yyjson_ptr_getx(yyjson_val *val, char *ptr, size_t len, yyjson_ptr_err *err);

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
		NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_get(yyjson_mut_doc *doc, char *ptr);

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
		NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_getn(yyjson_mut_doc *doc, char *ptr, size_t len);

	/**
	Get value by a JSON Pointer.
	@param doc The JSON document to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
		NULL if `doc` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_getx(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The value referenced by the JSON pointer.
		NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_get(yyjson_mut_val *val, char *ptr);

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The value referenced by the JSON pointer.
		NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_getn(yyjson_mut_val *val, char *ptr, size_t len);

	/**
	Get value by a JSON Pointer.
	@param val The JSON value to be queried.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The value referenced by the JSON pointer.
		NULL if `val` or `ptr` is NULL, or the JSON pointer cannot be resolved.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_getx(yyjson_mut_val *val, char *ptr, size_t len, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Add (insert) value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	[CLink] public static extern bool yyjson_mut_doc_ptr_add(yyjson_mut_doc *doc, char *ptr, yyjson_mut_val *new_val);

	/**
	Add (insert) value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	[CLink] public static extern bool yyjson_mut_doc_ptr_addn(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_mut_val *new_val);

	/**
	Add (insert) value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be added.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	*/
	[CLink] public static extern bool yyjson_mut_doc_ptr_addx(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_mut_val *new_val, bool create_parent, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Add (insert) value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param doc Only used to create new values when needed.
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	[CLink] public static extern bool yyjson_mut_ptr_add(yyjson_mut_val *val, char *ptr, yyjson_mut_val *new_val, yyjson_mut_doc *doc);

	/**
	Add (insert) value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param doc Only used to create new values when needed.
	@param new_val The value to be added.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	@note The parent nodes will be created if they do not exist.
	*/
	[CLink] public static extern bool yyjson_mut_ptr_addn(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_mut_doc *doc);

	/**
	Add (insert) value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param doc Only used to create new values when needed.
	@param new_val The value to be added.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is added, false otherwise.
	*/
	[CLink] public static extern bool yyjson_mut_ptr_addx(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_mut_doc *doc, bool create_parent, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Set value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The value to be set, pass NULL to remove.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
		If the target value already exists, it will be replaced by the new value.
	*/
	[CLink] public static extern bool yyjson_mut_doc_ptr_set(yyjson_mut_doc *doc, char *ptr, yyjson_mut_val *new_val);

	/**
	Set value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
		If the target value already exists, it will be replaced by the new value.
	*/
	[CLink] public static extern bool yyjson_mut_doc_ptr_setn(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_mut_val *new_val);

	/**
	Set value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note If the target value already exists, it will be replaced by the new value.
	*/
	[CLink] public static extern bool yyjson_mut_doc_ptr_setx(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_mut_val *new_val, bool create_parent, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Set value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The value to be set, pass NULL to remove.
	@param doc Only used to create new values when needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
		If the target value already exists, it will be replaced by the new value.
	*/
	[CLink] public static extern bool yyjson_mut_ptr_set(yyjson_mut_val *val, char *ptr, yyjson_mut_val *new_val, yyjson_mut_doc *doc);

	/**
	Set value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@param doc Only used to create new values when needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note The parent nodes will be created if they do not exist.
		If the target value already exists, it will be replaced by the new value.
	*/
	[CLink] public static extern bool yyjson_mut_ptr_setn(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_mut_doc *doc);

	/**
	Set value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The value to be set, pass NULL to remove.
	@param doc Only used to create new values when needed.
	@param create_parent Whether to create parent nodes if not exist.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return true if JSON pointer is valid and new value is set, false otherwise.
	@note If the target value already exists, it will be replaced by the new value.
	*/
	[CLink] public static extern bool yyjson_mut_ptr_setx(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_mut_doc *doc, bool create_parent, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Replace value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_replace(yyjson_mut_doc *doc, char *ptr, yyjson_mut_val *new_val);

	/**
	Replace value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_replacen(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_mut_val *new_val);

	/**
	Replace value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The old value that was replaced, or NULL if not found.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_replacex(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Replace value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_replace(yyjson_mut_val *val, char *ptr, yyjson_mut_val *new_val);

	/**
	Replace value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@return The old value that was replaced, or NULL if not found.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_replacen(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val);

	/**
	Replace value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param new_val The new value to replace the old one.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The old value that was replaced, or NULL if not found.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_replacex(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Remove value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The removed value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_remove(yyjson_mut_doc *doc, char *ptr);

	/**
	Remove value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The removed value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_removen(yyjson_mut_doc *doc, char *ptr, size_t len);

	/**
	Remove value by a JSON pointer.
	@param doc The target JSON document.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The removed value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_doc_ptr_removex(yyjson_mut_doc *doc, char *ptr, size_t len, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Remove value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8 with null-terminator).
	@return The removed value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_remove(yyjson_mut_val *val, char *ptr);

	/**
	Remove value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@return The removed value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_removen(yyjson_mut_val *val, char *ptr, size_t len);

	/**
	Remove value by a JSON pointer.
	@param val The target JSON value.
	@param ptr The JSON pointer string (UTF-8, null-terminator is not required).
	@param len The length of `ptr` in bytes.
	@param ctx A pointer to store the result context, or NULL if not needed.
	@param err A pointer to store the error information, or NULL if not needed.
	@return The removed value, or NULL on error.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_ptr_removex(yyjson_mut_val *val, char *ptr, size_t len, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/**
	Append value by JSON pointer context.
	@param ctx The context from the `yyjson_mut_ptr_xxx()` calls.
	@param key New key if `ctx->ctn` is object, or NULL if `ctx->ctn` is array.
	@param val New value to be added.
	@return true on success or false on fail.
	*/
	[CLink] public static extern bool yyjson_ptr_ctx_append(yyjson_ptr_ctx *ctx, yyjson_mut_val *key, yyjson_mut_val *val);

	/**
	Replace value by JSON pointer context.
	@param ctx The context from the `yyjson_mut_ptr_xxx()` calls.
	@param val New value to be replaced.
	@return true on success or false on fail.
	@note If success, the old value will be returned via `ctx->old`.
	*/
	[CLink] public static extern bool yyjson_ptr_ctx_replace(yyjson_ptr_ctx *ctx, yyjson_mut_val *val);

	/**
	Remove value by JSON pointer context.
	@param ctx The context from the `yyjson_mut_ptr_xxx()` calls.
	@return true on success or false on fail.
	@note If success, the old value will be returned via `ctx->old`.
	*/
	[CLink] public static extern bool yyjson_ptr_ctx_remove(yyjson_ptr_ctx *ctx);


	/*==============================================================================
	* JSON Patch API (RFC 6902)
	* https://tools.ietf.org/html/rfc6902
	*============================================================================*/

	/** Result code for JSON patch. */
	typealias yyjson_patch_code = uint32_t;

	/** Success, no error. */
	const yyjson_patch_code YYJSON_PATCH_SUCCESS = 0;

	/** Invalid parameter, such as NULL input or non-array patch. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_INVALID_PARAMETER = 1;

	/** Memory allocation failure occurs. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_MEMORY_ALLOCATION = 2;

	/** JSON patch operation is not object type. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_INVALID_OPERATION = 3;

	/** JSON patch operation is missing a required key. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_MISSING_KEY = 4;

	/** JSON patch operation member is invalid. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_INVALID_MEMBER = 5;

	/** JSON patch operation `test` not equal. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_EQUAL = 6;

	/** JSON patch operation failed on JSON pointer. */
	const yyjson_patch_code YYJSON_PATCH_ERROR_POINTER = 7;

	/** Error information for JSON patch. */
	[CRepr]
	struct yyjson_patch_err {
		/** Error code, see `yyjson_patch_code` for all possible values. */
		yyjson_patch_code code;
		/** Index of the error operation (0 if no error). */
		size_t idx;
		/** Error message, constant, no need to free (NULL if no error). */
		char *msg;
		/** JSON pointer error if `code == YYJSON_PATCH_ERROR_POINTER`. */
		yyjson_ptr_err ptr;
	}

	/**
	Creates and returns a patched JSON value (RFC 6902).
	The memory of the returned value is allocated by the `doc`.
	The `err` is used to receive error information, pass NULL if not needed.
	Returns NULL if the patch could not be applied.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_patch(yyjson_mut_doc *doc, yyjson_val *orig, yyjson_val *patch, yyjson_patch_err *err);

	/**
	Creates and returns a patched JSON value (RFC 6902).
	The memory of the returned value is allocated by the `doc`.
	The `err` is used to receive error information, pass NULL if not needed.
	Returns NULL if the patch could not be applied.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_patch(yyjson_mut_doc *doc, yyjson_mut_val *orig, yyjson_mut_val *patch, yyjson_patch_err *err);



	/*==============================================================================
	* JSON Merge-Patch API (RFC 7386)
	* https://tools.ietf.org/html/rfc7386
	*============================================================================*/

	/**
	Creates and returns a merge-patched JSON value (RFC 7386).
	The memory of the returned value is allocated by the `doc`.
	Returns NULL if the patch could not be applied.

	@warning This function is recursive and may cause a stack overflow if the
		object level is too deep.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_merge_patch(yyjson_mut_doc *doc, yyjson_val *orig, yyjson_val *patch);

	/**
	Creates and returns a merge-patched JSON value (RFC 7386).
	The memory of the returned value is allocated by the `doc`.
	Returns NULL if the patch could not be applied.

	@warning This function is recursive and may cause a stack overflow if the
		object level is too deep.
	*/
	[CLink] public static extern yyjson_mut_val *yyjson_mut_merge_patch(yyjson_mut_doc *doc, yyjson_mut_val *orig, yyjson_mut_val *patch);

#endif /* YYJSON_DISABLE_UTILS */

	/*==============================================================================
	* JSON Structure (Implementation)
	*============================================================================*/

	/** Payload of a JSON value (8 bytes). */
	[Union] 
	public struct yyjson_val_uni {
		uint64_t    u64;
		int64_t     i64;
		double      f64;
		char *str;
		void       *ptr;
		size_t      ofs;
	}

	/**
	Immutable JSON value, 16 bytes.
	*/
	[CRepr]
	public struct yyjson_val {
		uint64_t tag; /**< type, subtype and length */
		yyjson_val_uni uni; /**< payload */
	}

	[CRepr]
	public struct yyjson_doc {
		/** Root value of the document (nonnull). */
		yyjson_val *root;
		/** Allocator used by document (nonnull). */
		yyjson_alc alc;
		/** The total number of bytes read when parsing JSON (nonzero). */
		size_t dat_read;
		/** The total number of value read when parsing JSON (nonzero). */
		size_t val_read;
		/** The string pool used by JSON values (nullable). */
		char *str_pool;
	}

#if !YYJSON_DISABLE_UTILS

	/*==============================================================================
	* JSON Pointer API (Implementation)
	*============================================================================*/

	// #define yyjson_ptr_set_err(_code, _msg) do { \
	//     if (err) { \
	//         err->code = YYJSON_PTR_ERR_##_code; \
	//         err->msg = _msg; \
	//         err->pos = 0; \
	//     } \
	// } while(false)

	/* require: val != NULL, *ptr == '/', len > 0 */
	[CLink] public static extern yyjson_val *unsafe_yyjson_ptr_getx(yyjson_val *val, char *ptr, size_t len, yyjson_ptr_err *err);

	/* require: val != NULL, *ptr == '/', len > 0 */
	[CLink] public static extern yyjson_mut_val *unsafe_yyjson_mut_ptr_getx(yyjson_mut_val *val, char *ptr, size_t len, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/* require: val/new_val/doc != NULL, *ptr == '/', len > 0 */
	[CLink] public static extern bool unsafe_yyjson_mut_ptr_putx(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_mut_doc *doc, bool create_parent, bool insert_new, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/* require: val/err != NULL, *ptr == '/', len > 0 */
	[CLink] public static extern yyjson_mut_val *unsafe_yyjson_mut_ptr_replacex(yyjson_mut_val *val, char *ptr, size_t len, yyjson_mut_val *new_val, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);

	/* require: val/err != NULL, *ptr == '/', len > 0 */
	[CLink] public static extern yyjson_mut_val *unsafe_yyjson_mut_ptr_removex(yyjson_mut_val *val, char *ptr, size_t len, yyjson_ptr_ctx *ctx, yyjson_ptr_err *err);


#endif /* YYJSON_DISABLE_UTILS */
}