import Foundation
import UIKit
import PDFKit

// MARK: - PDF Exporter
/// Generates a professional PDF document from meeting data.
class PDFExporter {

    // MARK: - Generate PDF
    /// Creates a PDF file from a Meeting and returns its URL.
    static func generatePDF(from meeting: Meeting) -> URL? {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)

        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "MeetMind AI",
            kCGPDFContextAuthor as String: "MeetMind AI",
            kCGPDFContextTitle as String: meeting.title
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin

            // --- App Title ---
            let appTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.systemBlue
            ]
            let appTitle = "MeetMind AI — Meeting Notes"
            appTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: appTitleAttributes)
            yPosition += 30

            // --- Meeting Title ---
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 40)
            meeting.title.draw(in: titleRect, withAttributes: titleAttributes)
            yPosition += 45

            // --- Date & Duration ---
            let metaAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let metaText = "Date: \(meeting.fullDateString)  •  Duration: \(meeting.formattedDuration)"
            metaText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: metaAttributes)
            yPosition += 25

            // --- Divider ---
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)

            // --- Summary Section ---
            if !meeting.summary.isEmpty {
                yPosition = drawSectionHeader("Summary", at: yPosition, margin: margin, contentWidth: contentWidth, context: context, pageRect: pageRect)
                yPosition = drawBody(meeting.summary, at: yPosition, margin: margin, contentWidth: contentWidth, context: context, pageRect: pageRect)
                yPosition += 10
            }

            // --- Action Items Section ---
            if !meeting.actionItems.isEmpty {
                yPosition = checkPageBreak(yPosition: yPosition, context: context, pageRect: pageRect, margin: margin)
                yPosition = drawSectionHeader("Action Items", at: yPosition, margin: margin, contentWidth: contentWidth, context: context, pageRect: pageRect)
                yPosition = drawBody(meeting.actionItems, at: yPosition, margin: margin, contentWidth: contentWidth, context: context, pageRect: pageRect)
                yPosition += 10
            }

            // --- Transcript Section ---
            if !meeting.transcript.isEmpty {
                yPosition = checkPageBreak(yPosition: yPosition, context: context, pageRect: pageRect, margin: margin)
                yPosition = drawSectionHeader("Full Transcript", at: yPosition, margin: margin, contentWidth: contentWidth, context: context, pageRect: pageRect)
                yPosition = drawBody(meeting.transcript, at: yPosition, margin: margin, contentWidth: contentWidth, context: context, pageRect: pageRect)
            }
        }

        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(meeting.title.replacingOccurrences(of: " ", with: "_"))_notes.pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("❌ PDF write error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Drawing Helpers

    private static func drawSectionHeader(
        _ title: String,
        at yPosition: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect
    ) -> CGFloat {
        var y = yPosition
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 25)
        title.draw(in: headerRect, withAttributes: headerAttributes)
        y += 30
        return y
    }

    private static func drawBody(
        _ text: String,
        at yPosition: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect
    ) -> CGFloat {
        var y = yPosition
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        let attributedString = NSAttributedString(string: text, attributes: bodyAttributes)
        let textRect = CGRect(x: margin, y: y, width: contentWidth, height: pageRect.height - y - margin)
        let boundingRect = attributedString.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)

        // Handle multi-page text
        if y + boundingRect.height > pageRect.height - margin {
            // Draw what fits on this page, then continue on the next
            attributedString.draw(in: textRect)
            context.beginPage()
            y = margin
        } else {
            let drawRect = CGRect(x: margin, y: y, width: contentWidth, height: boundingRect.height)
            attributedString.draw(in: drawRect)
            y += boundingRect.height + 5
        }

        return y
    }

    private static func drawDivider(
        at yPosition: CGFloat,
        margin: CGFloat,
        width: CGFloat,
        in context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPosition))
        path.addLine(to: CGPoint(x: margin + width, y: yPosition))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        return yPosition + 15
    }

    private static func checkPageBreak(
        yPosition: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        margin: CGFloat
    ) -> CGFloat {
        if yPosition > pageRect.height - 100 {
            context.beginPage()
            return margin
        }
        return yPosition
    }
}
