defmodule Guardian.ClaimValidation do
  use Behaviour

  defcallback validate_claim(String.t, Map.t, Map.t) :: :ok | { :error, atom }

  defmacro __using__(_options \\ []) do
    quote do
      def validate_claim(:iss, payload, opts), do: validate_claim("iss", payload, opts)
      def validate_claim("iss", payload, _) do
        verify_issuer = Guardian.config(:verify_issuer, false)
        if verify_issuer do
          if Map.get(payload, "iss") == Guardian.config(:issuer), do: :ok, else: { :error, :invalid_issuer }
        else
          :ok
        end
      end

      def validate_claim(:nbf, payload, opts), do: validate_claim("nbf", payload, opts)
      def validate_claim("nbf", payload, _) do
        case Map.get(payload, "nbf") do
          nil -> :ok
          nbf -> if nbf > Guardian.Utils.timestamp, do: { :error, :token_not_yet_valid }, else: :ok
        end
      end

      def validate_claim(:iat, payload, opts), do: validate_claim("iat", payload, opts)
      def validate_claim("iat", payload, _) do
        case Map.get(payload, "iat") do
          nil -> :ok
          iat -> if iat > Guardian.Utils.timestamp, do: { :error, :token_not_yet_valid }, else: :ok
        end
      end

      def validate_claim(:exp, payload, opts), do: validate_claim("exp", payload, opts)
      def validate_claim("exp", payload, _) do

        case Map.get(payload, "exp") do
          nil -> :ok
          _ -> if Map.get(payload, "exp") < Guardian.Utils.timestamp, do: { :error, :token_expired }, else: :ok
        end
      end

      def validate_claim(:typ, payload, opts), do: validate_claim("typ", payload, opts)
      def validate_claim("typ", payload, opts) do
        has_typ_key? = Map.has_key?(opts, "typ")
        if has_typ_key? and Map.get(opts, "typ") != Map.get(payload, "typ") do
          { :error, :invalid_type }
        else
          :ok
        end
      end

      def validate_claim(:aud, payload, opts), do: validate_claim("aud", payload, opts)
      def validate_claim("aud", payload, opts) do
        has_aud_key? = Map.has_key?(opts, "aud")
        if has_aud_key? and Map.get(opts, "aud") != Map.get(payload, "aud") do
          { :error, :invalid_audience }
        else
          :ok
        end
      end
    end
  end
end
