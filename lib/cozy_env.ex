defmodule CozyEnv do
  @moduledoc """
  Helpers for handling OS environment variables.

  It helps to:

    * cast values of environment variables
    * provide user-friendly error messages

  """

  alias CozyEnv.EnvError

  @type data_type ::
          :boolean
          | :integer
          | :float
          | :string
          | :atom

  @type result ::
          boolean()
          | integer()
          | float()
          | String.t()
          | atom()

  @type option :: {:message, String.t()}
  @type options :: [option()]

  @supported_types [
    :boolean,
    :integer,
    :float,
    :string,
    :atom
  ]

  @doc """
  Gets the value of the given environment variable, and casts it into given type.

  If the environment variable is not set, returns `nil`.

  ## Examples

      iex> CozyEnv.get_env("NOT_SET", :boolean)
      nil

      # export PHX_SERVER=true
      iex> CozyEnv.get_env("PHX_SERVER", :boolean)
      true

      # export DB_POOL_SIZE=10
      iex> CozyEnv.get_env("DB_POOL_SIZE", :integer)
      10

      # export PERCENT=0.95
      iex> CozyEnv.get_env("PERCENT", :float)
      0.95

      # export USER=billy
      iex> CozyEnv.get_env("USER", :string)
      "billy"

      # export USER=billy
      iex> CozyEnv.get_env("USER", :atom)
      :billy

  """
  @spec get_env(String.t(), data_type()) :: result()
  def get_env(varname, type)
      when is_binary(varname) and type in @supported_types do
    case System.fetch_env(varname) do
      {:ok, value} ->
        apply(__MODULE__, :"to_#{type}", [varname, value])

      :error ->
        nil
    end
  end

  @spec get_env(String.t()) :: String.t()
  def get_env(varname), do: get_env(varname, :string)

  @doc """
  Gets the value of the given environment variable, and casts it into given type.

  If the environment variable is not set, raises an error.

  ## Examples

      iex> CozyEnv.fetch_env!("NOT_SET", :boolean)
      ** (CozyEnv.EnvError) environment variable NOT_SET is missing
          (cozy_env) lib/cozy_env.ex:134: CozyEnv.fetch_env!/3
          iex:1: (file)

      # export PHX_SERVER=true
      iex> CozyEnv.fetch_env!("PHX_SERVER", :boolean)
      true

      # export DB_POOL_SIZE=10
      iex> CozyEnv.fetch_env!("DB_POOL_SIZE", :integer)
      10

      # export PERCENT=0.95
      iex> CozyEnv.fetch_env!("PERCENT", :float)
      0.95

      # export USER=billy
      iex> CozyEnv.fetch_env!("USER", :string)
      "billy"

      # export USER=billy
      iex> CozyEnv.fetch_env!("USER", :atom)
      :billy

  """
  @spec fetch_env!(String.t(), data_type(), options()) :: result()
  def fetch_env!(varname, type, opts)
      when is_binary(varname) and type in @supported_types and is_list(opts) do
    case System.fetch_env(varname) do
      {:ok, value} ->
        apply(__MODULE__, :"to_#{type}", [varname, value])

      :error ->
        default_message = "environment variable #{varname} is missing"
        extra_message = Keyword.get(opts, :message)

        message =
          if extra_message do
            """
            #{default_message}.
            #{extra_message}
            """
          else
            default_message
          end

        raise EnvError, message
    end
  end

  @spec fetch_env!(String.t(), data_type()) :: result()
  def fetch_env!(varname, type) when is_binary(varname) and is_atom(type) do
    fetch_env!(varname, type, [])
  end

  @spec fetch_env!(String.t(), options()) :: String.t()
  def fetch_env!(varname, opts) when is_binary(varname) and is_list(opts) do
    fetch_env!(varname, :string, opts)
  end

  @spec fetch_env!(String.t()) :: String.t()
  def fetch_env!(varname) when is_binary(varname) do
    fetch_env!(varname, :string, [])
  end

  @doc false
  def to_boolean(_varname, "false"), do: false
  def to_boolean(_varname, "0"), do: false
  def to_boolean(_varname, ""), do: false
  def to_boolean(_varname, _), do: true

  @doc false
  def to_integer(varname, value) do
    case Integer.parse(value) do
      {integer, ""} ->
        integer

      _ ->
        raise EnvError,
              "environment variable #{varname} is provided, but the value " <>
                "#{inspect(value)} is not the string representation of an integer"
    end
  end

  @doc false
  def to_float(varname, value) do
    case Float.parse(value) do
      {float, ""} ->
        float

      _ ->
        raise EnvError,
              "environment variable #{varname} is provided, but the value " <>
                "#{inspect(value)} is not the string representation of a float"
    end
  end

  @doc false
  def to_string(_varname, value), do: value

  @doc false
  def to_atom(_varname, value), do: String.to_atom(value)
end

defmodule CozyEnv.EnvError do
  defexception [:message]
end
