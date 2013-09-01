# Create error
def create_error_hash(code, message)
  return { "error" => {
             "code" => code,
             "message" => message
           }
         }
end