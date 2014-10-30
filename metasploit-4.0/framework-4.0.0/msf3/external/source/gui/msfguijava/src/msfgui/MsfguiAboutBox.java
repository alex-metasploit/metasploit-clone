package msfgui;

import org.jdesktop.application.Action;

/**
 * Provides an about box for msfgui.
 * @author scriptjunkie
 */
public class MsfguiAboutBox extends javax.swing.JDialog {

	public static void show(java.awt.Frame parent, RpcConnection rpcConn){
		java.util.Map version = new java.util.HashMap();
		if(rpcConn != null) {
			version = (java.util.Map)rpcConn.execute("core.version");
		} else {
			version.put("version", "4");
			version.put("ruby", "");
		}
		MsfguiApp.getApplication().show(new MsfguiAboutBox(parent, version.get("version").toString(),
				version.get("ruby").toString(),
				System.getProperty("java.version")+" "+System.getProperty("java.vendor")));
	}
	public MsfguiAboutBox(java.awt.Frame parent, String msfVersion, String rubyVersion, String javaVersion) {
		super(parent);
		initComponents();
		getRootPane().setDefaultButton(closeButton);
		appVersionLabel.setText(msfVersion);
		appJavaVersionLabel.setText(javaVersion);
		appRubyVersionLabel.setText(rubyVersion);
		org.jdesktop.application.ResourceMap resourceMap = org.jdesktop.application.Application.getInstance(msfgui.MsfguiApp.class).getContext().getResourceMap(ModulePopup.class);
		this.setIconImage(resourceMap.getImageIcon("main.icon").getImage());
	}

	@Action public void closeAboutBox() {
		dispose();
	}

	/** This method is called from within the constructor to
	 * initialize the form.
	 * WARNING: Do NOT modify this code. The content of this method is
	 * always regenerated by the Form Editor.
	 */
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        closeButton = new javax.swing.JButton();
        javax.swing.JLabel appTitleLabel = new javax.swing.JLabel();
        javax.swing.JLabel versionLabel = new javax.swing.JLabel();
        appVersionLabel = new javax.swing.JLabel();
        javax.swing.JLabel homepageLabel = new javax.swing.JLabel();
        javax.swing.JLabel appHomepageLabel = new javax.swing.JLabel();
        javax.swing.JLabel appDescLabel = new javax.swing.JLabel();
        javax.swing.JLabel imageLabel = new javax.swing.JLabel();
        javax.swing.JLabel rubyVersionLabel = new javax.swing.JLabel();
        javax.swing.JLabel javaVersionLabel = new javax.swing.JLabel();
        appRubyVersionLabel = new javax.swing.JLabel();
        appJavaVersionLabel = new javax.swing.JLabel();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        org.jdesktop.application.ResourceMap resourceMap = org.jdesktop.application.Application.getInstance(msfgui.MsfguiApp.class).getContext().getResourceMap(MsfguiAboutBox.class);
        setTitle(resourceMap.getString("title")); // NOI18N
        setModal(true);
        setResizable(false);

        javax.swing.ActionMap actionMap = org.jdesktop.application.Application.getInstance(msfgui.MsfguiApp.class).getContext().getActionMap(MsfguiAboutBox.class, this);
        closeButton.setAction(actionMap.get("closeAboutBox")); // NOI18N
        closeButton.setName("closeButton"); // NOI18N

        appTitleLabel.setFont(appTitleLabel.getFont().deriveFont(appTitleLabel.getFont().getStyle() | java.awt.Font.BOLD, appTitleLabel.getFont().getSize()+8));
        appTitleLabel.setText(resourceMap.getString("Application.title")); // NOI18N
        appTitleLabel.setName("appTitleLabel"); // NOI18N

        versionLabel.setFont(versionLabel.getFont().deriveFont(versionLabel.getFont().getStyle() | java.awt.Font.BOLD));
        versionLabel.setHorizontalAlignment(javax.swing.SwingConstants.TRAILING);
        versionLabel.setText(resourceMap.getString("versionLabel.text")); // NOI18N
        versionLabel.setName("versionLabel"); // NOI18N

        appVersionLabel.setText(resourceMap.getString("Application.version")); // NOI18N
        appVersionLabel.setName("appVersionLabel"); // NOI18N

        homepageLabel.setFont(homepageLabel.getFont().deriveFont(homepageLabel.getFont().getStyle() | java.awt.Font.BOLD));
        homepageLabel.setHorizontalAlignment(javax.swing.SwingConstants.TRAILING);
        homepageLabel.setText(resourceMap.getString("homepageLabel.text")); // NOI18N
        homepageLabel.setName("homepageLabel"); // NOI18N

        appHomepageLabel.setText(resourceMap.getString("Application.homepage")); // NOI18N
        appHomepageLabel.setName("appHomepageLabel"); // NOI18N

        appDescLabel.setText(resourceMap.getString("appDescLabel.text")); // NOI18N
        appDescLabel.setName("appDescLabel"); // NOI18N

        imageLabel.setIcon(resourceMap.getIcon("imageLabel.icon")); // NOI18N
        imageLabel.setName("imageLabel"); // NOI18N

        rubyVersionLabel.setFont(rubyVersionLabel.getFont().deriveFont(rubyVersionLabel.getFont().getStyle() | java.awt.Font.BOLD));
        rubyVersionLabel.setText(resourceMap.getString("rubyVersionLabel.text")); // NOI18N
        rubyVersionLabel.setName("rubyVersionLabel"); // NOI18N

        javaVersionLabel.setFont(javaVersionLabel.getFont().deriveFont(javaVersionLabel.getFont().getStyle() | java.awt.Font.BOLD));
        javaVersionLabel.setHorizontalAlignment(javax.swing.SwingConstants.TRAILING);
        javaVersionLabel.setText(resourceMap.getString("javaVersionLabel.text")); // NOI18N
        javaVersionLabel.setName("javaVersionLabel"); // NOI18N

        appRubyVersionLabel.setText(resourceMap.getString("appRubyVersionLabel.text")); // NOI18N
        appRubyVersionLabel.setName("appRubyVersionLabel"); // NOI18N

        appJavaVersionLabel.setText(resourceMap.getString("appJavaVersionLabel.text")); // NOI18N
        appJavaVersionLabel.setName("appJavaVersionLabel"); // NOI18N

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(imageLabel)
                .addGap(18, 18, 18)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(appTitleLabel, javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(appDescLabel, javax.swing.GroupLayout.Alignment.LEADING, javax.swing.GroupLayout.DEFAULT_SIZE, 466, Short.MAX_VALUE)
                    .addGroup(javax.swing.GroupLayout.Alignment.LEADING, layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING, false)
                            .addComponent(homepageLabel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(javaVersionLabel, javax.swing.GroupLayout.Alignment.LEADING, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(versionLabel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(rubyVersionLabel, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                            .addGroup(layout.createSequentialGroup()
                                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                                    .addComponent(appVersionLabel)
                                    .addComponent(appRubyVersionLabel)
                                    .addComponent(appJavaVersionLabel))
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 353, Short.MAX_VALUE))
                            .addComponent(appHomepageLabel, javax.swing.GroupLayout.DEFAULT_SIZE, 361, Short.MAX_VALUE)))
                    .addComponent(closeButton))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(imageLabel, javax.swing.GroupLayout.PREFERRED_SIZE, 305, Short.MAX_VALUE)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(appTitleLabel)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(appDescLabel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(versionLabel)
                    .addComponent(appVersionLabel))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(rubyVersionLabel)
                    .addComponent(appRubyVersionLabel))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(javaVersionLabel)
                    .addComponent(appJavaVersionLabel))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(homepageLabel)
                    .addComponent(appHomepageLabel))
                .addGap(104, 104, 104)
                .addComponent(closeButton)
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents
	
    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel appJavaVersionLabel;
    private javax.swing.JLabel appRubyVersionLabel;
    private javax.swing.JLabel appVersionLabel;
    private javax.swing.JButton closeButton;
    // End of variables declaration//GEN-END:variables
	
}