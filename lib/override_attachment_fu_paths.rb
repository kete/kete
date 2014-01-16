module OverrideAttachmentFuPaths
  def partitioned_path(*args)
    # Overrides partitioned_path defined in attachment_fu

    # changed from %08d to %012d to be extra safe
    # avoiding directory naming collisions with legacy directories
    ("%012d" % attachment_path_id).scan(/..../) + args

    # ROB: attachment path had a legacy version for systems that didn't upgrade
    #      their file-system organisation:  [attachment_path_id.to_s] + args
  end
end



