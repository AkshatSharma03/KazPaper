#!/usr/bin/env python3
"""
Add detailed descriptions and captions to existing figures using PIL/Pillow
"""

import os
from PIL import Image, ImageDraw, ImageFont
import textwrap

# Figure descriptions from FIGURE_DESCRIPTIONS.md
figure_captions = {
    "fig1_export_composition": {
        "title": "Figure 1: Kazakhstan's Exports to China by Sector, 2015-2024",
        "caption": "Energy and metals dominate exports (45% and 35% respectively). Total exports grew 120% from $8.4B to $18.5B.",
        "insight": "KEY INSIGHT: Commodity-dependent export structure with no significant diversification into manufactured goods.",
    },
    "fig2_import_composition": {
        "title": "Figure 2: Kazakhstan's Imports from China by Sector, 2015-2024",
        "caption": "Machinery (30%), vehicles (20%), and textiles (15%) dominate imports. Total grew 263% from $6.2B to $22.5B—2.3x faster than exports.",
        "insight": "KEY INSIGHT: The 263% import surge (vs 120% export growth) creates the asymmetry driving the 2023 trade deficit.",
    },
    "fig3_sectoral_balance": {
        "title": "Figure 3: Kazakhstan-China Trade Balance by Major Sector, 2015-2024",
        "caption": "Energy and metals maintain large surpluses (+$8-12B annually). Machinery and vehicles shifted to deficits (-$2 to -$4B).",
        "insight": "KEY INSIGHT: The 2023 inflection reflects sector-specific deterioration in machinery and vehicles, not an aggregate shock.",
    },
    "fig4_china_penetration": {
        "title": "Figure 4: China's Import Penetration by Sector, 2015-2024",
        "caption": "China supplies 77.3% of machinery, 84.5% of vehicles, and 89.8% of textile imports by 2023.",
        "insight": "KEY INSIGHT: Extreme dominance in key sectors reflects supply chain concentration and limited domestic manufacturing capacity.",
    },
    "fig6_concentration_index": {
        "title": "Figure 6: Trade Concentration Index, 2015-2024",
        "caption": "HHI remains stable at 0.25-0.35, indicating persistent commodity sector dominance with no diversification.",
        "insight": "KEY INSIGHT: Stable index confirms commodity-dependent relationship unchanged across the decade.",
    },
    "fig7_asymmetry_index": {
        "title": "Figure 7: Trade Growth Asymmetry Index, 2015-2024",
        "caption": "Asymmetry deteriorated from ~0.8 (2015-2020) to 1.8-2.5 (2021-2024). Imports growing 1.8-2.5x faster than exports.",
        "insight": "KEY INSIGHT: Escalating asymmetry is the primary driver of the 2023 trade balance reversal.",
    },
    "fig8_vulnerability_multivector": {
        "title": "Figure 8: Trade Vulnerability - Multidimensional Framework, 2015-2024",
        "caption": "Three vulnerability dimensions worsen simultaneously: sectoral concentration (0.25-0.35 HHI), bilateral dependency, and penetration levels (77-90%).",
        "insight": "KEY INSIGHT: Multi-dimensional vulnerability indicates cumulative exposure risk across concentration, partner dependency, and import penetration.",
    },
    "fig9_sectoral_penetration_heatmap": {
        "title": "Figure 9: Sectoral Import Penetration Heatmap, 2015-2024",
        "caption": "China dominates import sectors (77-90%) while having minimal penetration in export sectors (<30%).",
        "insight": "KEY INSIGHT: Stark sectoral differentiation reflects Kazakhstan's role specialization: raw materials provider and manufactured goods consumer.",
    },
    "fig10_2023_structural_shift": {
        "title": "Figure 10: 2023 Structural Shift - Sectoral Before/After Analysis",
        "caption": "Machinery shifted from +$0.3B average surplus (2015-2022) to -$3.4B average deficit (2023-2024). Vehicles shifted from +$0.1B to -$2.3B deficit.",
        "insight": "KEY INSIGHT: ~$6B sectoral shift explains overall balance reversal; 2024 persistence confirms structural nature.",
    },
    "fig11_hedging_behavior": {
        "title": "Figure 11: Post-2023 Hedging Behavior - Partner Shares",
        "caption": "China's import share increased from 28.4% (2015-2022) to 30.1% (2023-2024). No diversification to alternative partners occurred.",
        "insight": "KEY INSIGHT: Lack of hedging behavior suggests structural entrenchment rather than temporary imbalance.",
    },
    "fig12_trade_flows": {
        "title": "Figure 12: Bilateral Trade Flows - Exports vs Imports, 2015-2024",
        "caption": "Exports grew from $8.4B to $18.5B (+120%). Imports grew from $6.2B to $22.5B (+263%). Lines crossed into deficit in 2023.",
        "insight": "KEY INSIGHT: Persistent divergence post-2022 (not cyclical variation) defines the structural shift.",
    },
    "fig13_trade_balance": {
        "title": "Figure 13: Aggregate Trade Balance Evolution, 2015-2024",
        "caption": "Average surplus 2015-2022: +$5.1B. Peak 2022: +$13.8B. 2023: -$4.0B. 2024: -$3.8B. Total swing: $17.8B.",
        "insight": "KEY INSIGHT: Eight consecutive years of surpluses reversed to deficits in 2023-2024, marking clearest inflection point in the decade.",
    },
    "fig14_deficit_ratio": {
        "title": "Figure 14: Deficit Ratio Evolution - Imports as % of Exports, 2015-2024",
        "caption": "Ratio rose smoothly from 74% (2015) to 122% (2024), crossing parity in 2023. Upward trend has R²>0.95.",
        "insight": "KEY INSIGHT: Smooth monotonic deterioration with high R² indicates predictable structural change, not temporary shock.",
    },
}


def add_caption_to_image(image_path, caption_info, output_path=None):
    """
    Add caption and description to the bottom of an image
    """
    if output_path is None:
        output_path = image_path

    try:
        img = Image.open(image_path)
        width, height = img.size

        # Create new image with space for text at bottom
        text_height = 280  # Adjust based on amount of text
        new_height = height + text_height
        new_img = Image.new("RGB", (width, new_height), color="white")

        # Paste original image
        new_img.paste(img, (0, 0))

        # Add text
        draw = ImageDraw.Draw(new_img)

        # Try to use a nice font, fall back to default
        try:
            title_font = ImageFont.truetype("/Library/Fonts/Arial.ttf", 16)
            text_font = ImageFont.truetype("/Library/Fonts/Arial.ttf", 12)
            insight_font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", 11)
        except:
            title_font = ImageFont.load_default()
            text_font = ImageFont.load_default()
            insight_font = ImageFont.load_default()

        y_offset = height + 10

        # Title
        draw.text((20, y_offset), caption_info["title"], fill="black", font=title_font)
        y_offset += 25

        # Caption (wrapped)
        caption_lines = textwrap.wrap(caption_info["caption"], width=120)
        for line in caption_lines:
            draw.text((20, y_offset), line, fill="#333333", font=text_font)
            y_offset += 20

        y_offset += 5

        # Insight (wrapped, highlighted)
        insight_lines = textwrap.wrap(caption_info["insight"], width=120)
        for line in insight_lines:
            draw.text((20, y_offset), line, fill="#cc0000", font=insight_font)
            y_offset += 18

        # Save
        new_img.save(output_path)
        return True

    except Exception as e:
        print(f"Error processing {image_path}: {str(e)}")
        return False


def main():
    """
    Process all figures and add captions
    """
    figures_dir = "figures"

    if not os.path.exists(figures_dir):
        print(f"Figures directory {figures_dir} not found")
        return

    print("Annotating figures with detailed descriptions...")
    print("=" * 60)

    # Only process PNG files (to avoid duplicates with PDF)
    for fig_name, caption_info in figure_captions.items():
        png_path = os.path.join(figures_dir, f"{fig_name}.png")

        if os.path.exists(png_path):
            # Create annotated version with _annotated suffix
            output_path = os.path.join(figures_dir, f"{fig_name}_annotated.png")

            print(f"Processing {fig_name}...", end=" ")
            if add_caption_to_image(png_path, caption_info, output_path):
                print("✓")
            else:
                print("✗ (failed)")
        else:
            print(f"Skipping {fig_name} - file not found")

    print("=" * 60)
    print("Annotation complete!")
    print("\nAnnotated figures saved with '_annotated' suffix.")
    print("Original figures preserved for compatibility.")


if __name__ == "__main__":
    main()
