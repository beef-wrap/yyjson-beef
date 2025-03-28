using System;
using System.Collections;
using System.Diagnostics;
using System.IO;

using static yyjson.yyjson;

namespace example;

static class Program
{
	static String json_sample = """
	{
		"name": "Mash",
		"star": 4,
		"hits": [2, 2, 1, 3]
	}
	""";

	static int Main(params String[] args)
	{
		// Read JSON and get root
		yyjson_doc* doc = yyjson_read(json_sample, (.)json_sample.Length, 0);
		yyjson_val* root = yyjson_doc_get_root(doc);

		yyjson_mut_val_mut_copy(null, null);

		// Get root["name"]
		yyjson_val* name = yyjson_obj_get(root, "name");
		Debug.WriteLine($"name: {StringView(yyjson_get_str(name))}\n");
		Debug.WriteLine($"name length:{yyjson_get_len(name)}\n");

		// Get root["star"]
		yyjson_val* star = yyjson_obj_get(root, "star");
		Debug.WriteLine($"star: {yyjson_get_int(star)}\n");

		// Get root["hits"], iterate over the array
		yyjson_val* hits = yyjson_obj_get(root, "hits");
		yyjson_arr_iter iter;
		yyjson_arr_iter_init(hits, &iter);
		yyjson_val* val;

		while ((val = yyjson_arr_iter_next(&iter)) != null)
		{
			Debug.WriteLine($"{yyjson_get_int(val)}, ");
		}

		// Free the doc
		yyjson_doc_free(doc);

		return 0;
	}
}