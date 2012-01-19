Paperclip.interpolates :client_folder do |attachment, style|
  if attachment.instance.bien
	p = attachment.instance.bien.passerelle
  else
    p = attachment.instance.passerelle
  end
  if p && p.installation && p.installation.client
    p.installation.client.id
  else
	$default_client_folder
  end
end

Paperclip.interpolates :execution_client_folder do |attachment, style|
  if attachment.instance.execution
	attachment.instance.execution.passerelle.installation.client.id
  else
    $firmware_folder
  end
end