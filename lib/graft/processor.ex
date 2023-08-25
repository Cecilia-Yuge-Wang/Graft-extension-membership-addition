defmodule Graft.Processor do
   @doc """
  Function to calculate runtime by subtracting the time recorded in the two files.
  """

  def process_files(file1_path, file2_path, output_path) do
    {values1, values2} = {read_values(file1_path), read_values(file2_path)}

    diff_results = Enum.zip(values1, values2)
                   |> Enum.map(fn {val1, val2} -> val1 - val2 end)

    write_results(output_path, diff_results)
  end

    defp read_values(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          content
          |> String.split("\n", trim: true)
          |> Enum.map(&String.to_integer/1)
        _ ->
          []
      end
    end

    defp write_results(file_path, results) do
      File.write(file_path, Enum.join(results, "\n"))
    end

end
