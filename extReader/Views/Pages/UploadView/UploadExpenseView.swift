//
//  UploadExpenseView.swift
//  extReader
//
//  Created by Renato Dias on 17/06/25.
//
import SwiftUI
import UniformTypeIdentifiers

struct UploadExpenseView: View {
    var onSuccess: (ExpenseResponse) -> Void
    @EnvironmentObject var fileSelector: FileSelectionManager
    @State private var showingDocumentPicker = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var invalidFileName = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showPremiumAlert = false
    private let maxFileCount = 6
    private let maxFileSizeBytes = 512 * 1024
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 20) {
                HStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 240)
                        .accessibilityLabel("Somai")
                }
                Spacer()
                // Header
                Text("Comprovantes de Despesa")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Selected Files List
                if (!$fileSelector.selectedFiles.isEmpty){
                    SelectedFilesView(selectedFiles: $fileSelector.selectedFiles)
                }
                else{
                    NoFilesView()
                        .onTapGesture {
                            showingDocumentPicker = true
                        }
                }
                
                // Pick Files Button
                HStack{
                    Button(action: {showingDocumentPicker = true})
                    {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Escolha arquivos")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill($fileSelector.selectedFiles.count >= maxFileCount ? Color.gray : Color(red: 15/255, green: 25/255, blue: 20/255))
                        )
                    }
                    .disabled($fileSelector.selectedFiles.count >= maxFileCount)
                    if $fileSelector.selectedFiles.count > 0 {
                        Button(action: {
                            Task {
                                await sendFiles(files: fileSelector.selectedFiles) { invalid in
                                    invalidFileName = invalid.lastPathComponent
                                    showAlert = true
                                }
                            }
                        })
                        {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Analisar")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill($fileSelector.selectedFiles.count >= maxFileCount ? Color.gray : Color(red: 15/255, green: 25/255, blue: 20/255))
                            )
                        }
                        .disabled(isLoading)
                    }
                }
                .alert("Arquivo Inválido", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("'\(invalidFileName)' não é um PDF. Apenas arquivos PDF são permitidos.")
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    selectedFiles: $fileSelector.selectedFiles,
                    maxFileCount: maxFileCount
                )
            }
            if isLoading {
            Color.black.opacity(0.4) // dim background
            .ignoresSafeArea()
            ProgressView("Carregando...")
                .padding()
                .cornerRadius(10)
            }
            Spacer()
        }
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Premium necessário", isPresented: $showPremiumAlert) {
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta funcionalidade requer uma assinatura Premium.")
        }
    }
    
    func sendFiles(files: [URL], onInvalid: (_ invalidFile: URL) -> Void) async {
        for file in files {
            if file.pathExtension.lowercased() != "pdf" {
                onInvalid(file)
                return
            }
        }
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               size > maxFileSizeBytes {
                errorMessage = "'\(file.lastPathComponent)' excede o limite de 512 KB."
                showErrorAlert = true
                return
            }
        }
        isLoading = true
        do {
            let res = try await ExpenseService.shared.processFiles(files)
            onSuccess(res)
            fileSelector.selectedFiles.removeAll()
        } catch ExpenseService.NetworkError.premiumRequired {
            showPremiumAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }
    
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [URL]
    let maxFileCount: Int
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Calculate how many more files we can add
            let remainingSlots = parent.maxFileCount - parent.selectedFiles.count
            let urlsToAdd = Array(urls.prefix(remainingSlots))
            
            // Filter out duplicates
            let newUrls = urlsToAdd.filter { newUrl in
                !parent.selectedFiles.contains { existingUrl in
                    existingUrl.lastPathComponent == newUrl.lastPathComponent
                }
            }
            
            parent.selectedFiles.append(contentsOf: newUrls)
        }
    }
}


