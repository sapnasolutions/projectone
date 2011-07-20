Paperclip.interpolates :client_folder do |attachment, style|
  if attachment.instance.bien
	attachment.instance.bien.passerelle.installation.client.id
  elsif @passerelle && @passerelle.installation && @passerelle.installation.client
    @passerelle.installation.client.id
  else
	$default_client_folder
  end
end

Paperclip.interpolates :execution_client_folder do |attachment, style|
  attachment.instance.execution.passerelle.installation.client.id
end